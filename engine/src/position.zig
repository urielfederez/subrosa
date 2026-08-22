const std = @import("std");

const constants = @import("constants.zig");
const Mask = constants.Mask;
const core = @import("core.zig");
const Color = core.Color;
const BoardSize = core.BoardSize;
const PieceType = core.PieceType;
const Bitboard = core.Bitboard;
const knights = @import("move_generation/knights.zig");
const pawns = @import("move_generation/pawns.zig");

pub const Move = struct {
    from: u8,
    to: u8,

    const Self = @This();

    pub fn format(
        self: Self,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        const fromFile = self.from % BoardSize;
        const fromRank = self.from / BoardSize;
        const toFile = self.to % BoardSize;
        const toRank = self.to / BoardSize;

        try writer.print("{c}{}{c}{}", .{ 'A' + fromFile, fromRank + 1, 'A' + toFile, toRank + 1 });
    }
};

pub const MoveList = struct {
    moves: [218]Move,
    length: u32 = 0,

    const Self = @This();

    pub fn new() Self {
        return .{
            .moves = std.mem.zeroes([218]Move),
            .length = 0,
        };
    }

    pub fn format(
        self: Self,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        try writer.print("{} legal moves: ", .{self.length});
        try writer.print("[", .{});
        for (0..self.length) |i| {
            try writer.print("{f}", .{self.moves[i]});
            if (i < self.length - 1) {
                try writer.print(", ", .{});
            }
        }
        try writer.print("]", .{});
    }

    pub fn add(self: *Self, move: Move) void {
        self.moves[self.length] = move;
        self.length += 1;
    }
};

pub const Position = struct {
    pieces: [Color.All][PieceType.All]u64,
    isWhiteTurn: bool,

    const Self = @This();

    pub fn new() Self {
        var pieces: [Color.All][PieceType.All]u64 = .{.{0} ** PieceType.All} ** Color.All;

        pieces[Color.White][PieceType.Pawn] = Mask.Rank2;
        pieces[Color.White][PieceType.Rook] = Mask.A1 | Mask.H1;
        pieces[Color.White][PieceType.Knight] = Mask.B1 | Mask.G1;
        pieces[Color.White][PieceType.Bishop] = Mask.C1 | Mask.F1;
        pieces[Color.White][PieceType.Queen] = Mask.D1;
        pieces[Color.White][PieceType.King] = Mask.E1;

        pieces[Color.Black][PieceType.Pawn] = Mask.Rank7;
        pieces[Color.Black][PieceType.Rook] = Mask.A8 | Mask.H8;
        pieces[Color.Black][PieceType.Knight] = Mask.B8 | Mask.G8;
        pieces[Color.Black][PieceType.Bishop] = Mask.C8 | Mask.F8;
        pieces[Color.Black][PieceType.Queen] = Mask.D8;
        pieces[Color.Black][PieceType.King] = Mask.E8;

        return .{
            .pieces = pieces,
            .isWhiteTurn = true,
        };
    }

    pub fn getOccupancy(self: Self, side: u64) Bitboard {
        var occupancy: Bitboard = 0;

        for (0..PieceType.All) |t| {
            occupancy |= self.pieces[side][t];
        }

        return occupancy;
    }

    fn getPawnMoves(self: Self, moveList: *MoveList) void {
        const whiteOccupancy = self.getOccupancy(Color.White);
        const blackOccupancy = self.getOccupancy(Color.Black);

        const color: u64 = if (self.isWhiteTurn) Color.White else Color.Black;
        var currentPawns = self.pieces[color][PieceType.Pawn];

        while (currentPawns != 0) {
            const pos = @ctz(currentPawns);
            var moves = pawns.pawn_moves[color][pos] & ~(whiteOccupancy | blackOccupancy);

            while (moves != 0) {
                const to = @ctz(moves);
                moveList.add(.{ .from = pos, .to = to });
                moves &= moves - 1;
            }
            currentPawns &= currentPawns - 1;

            var attacks = pawns.pawn_attacks[color][pos] & blackOccupancy;
            while (attacks != 0) {
                const to = @ctz(attacks);
                moveList.add(.{ .from = pos, .to = to });
                attacks &= attacks - 1;
            }
        }
    }

    fn getKnightMoves(self: Self, moveList: *MoveList) void {
        const color: u64 = if (self.isWhiteTurn) Color.White else Color.Black;
        const sameSideOccupancy = self.getOccupancy(color);
        var currentKnights = self.pieces[color][PieceType.Knight];

        while (currentKnights != 0) {
            const pos = @ctz(currentKnights);

            var moves = knights.knight_moves[pos] & ~sameSideOccupancy;

            while (moves != 0) {
                const to = @ctz(moves);
                moveList.add(.{ .from = pos, .to = to });
                moves &= moves - 1;
            }
            currentKnights &= currentKnights - 1;
        }
    }

    fn getRookMoves(self: Self, moveList: *MoveList) void {
        const color: u64 = if (self.isWhiteTurn) Color.White else Color.Black;
        const oppositeColor: u64 = if (self.isWhiteTurn) Color.Black else Color.White;

        const sameSideOccupancy = self.getOccupancy(color);
        const oppositeOccupancy = self.getOccupancy(oppositeColor);

        var currentRooks = self.pieces[color][PieceType.Rook];

        while (currentRooks != 0) {
            const pos: u6 = @as(u6, @intCast(@ctz(currentRooks)));
            const file = @as(u6, pos) % @as(u6, BoardSize);
            const rank = @as(u6, pos) / @as(u6, BoardSize);

            for (0..file) |currFile| {
                const posMask = @as(u64, 1) << (rank * BoardSize + @as(u6, @intCast(currFile)));
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = rank * BoardSize + @as(u8, @intCast(currFile)) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (file + 1..BoardSize) |currFile| {
                const posMask = @as(u64, 1) << (rank * BoardSize + @as(u6, @intCast(currFile)));
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = rank * BoardSize + @as(u8, @intCast(currFile)) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (0..rank) |currRank| {
                const posMask = @as(u64, 1) << (@as(u6, @intCast(currRank)) * BoardSize + file);
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = (@as(u8, @intCast(currRank)) * BoardSize + file) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (rank + 1..BoardSize) |currRank| {
                const posMask = @as(u64, 1) << (@as(u6, @intCast(currRank)) * BoardSize + file);
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = (@as(u8, @intCast(currRank)) * BoardSize + file) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            currentRooks &= currentRooks - 1;
        }
    }

    fn getBishopMoves(self: Self, moveList: *MoveList) void {
        const color: u64 = if (self.isWhiteTurn) Color.White else Color.Black;
        const oppositeColor: u64 = if (self.isWhiteTurn) Color.Black else Color.White;

        const sameSideOccupancy = self.getOccupancy(color);
        const oppositeOccupancy = self.getOccupancy(oppositeColor);

        var currentBishops = self.pieces[color][PieceType.Bishop];

        while (currentBishops != 0) {
            const pos: u6 = @as(u6, @intCast(@ctz(currentBishops)));
            const file = @as(u6, pos) % @as(u6, BoardSize);
            const rank = @as(u6, pos) / @as(u6, BoardSize);

            for (0..file) |currFile| {
                const posMask = @as(u64, 1) << (rank * BoardSize + @as(u6, @intCast(currFile)));
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = rank * BoardSize + @as(u8, @intCast(currFile)) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (file + 1..BoardSize) |currFile| {
                const posMask = @as(u64, 1) << (rank * BoardSize + @as(u6, @intCast(currFile)));
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = rank * BoardSize + @as(u8, @intCast(currFile)) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (0..rank) |currRank| {
                const posMask = @as(u64, 1) << (@as(u6, @intCast(currRank)) * BoardSize + file);
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = (@as(u8, @intCast(currRank)) * BoardSize + file) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            for (rank + 1..BoardSize) |currRank| {
                const posMask = @as(u64, 1) << (@as(u6, @intCast(currRank)) * BoardSize + file);
                if ((posMask & sameSideOccupancy) > 0) {
                    break;
                }
                moveList.add(.{ .from = pos, .to = (@as(u8, @intCast(currRank)) * BoardSize + file) });
                if ((posMask & oppositeOccupancy) > 0) {
                    break;
                }
                break;
            }

            currentBishops &= currentBishops - 1;
        }
    }

    pub fn getAllLegalMoves(self: Self) MoveList {
        var moveList = MoveList.new();

        self.getPawnMoves(&moveList);
        self.getKnightMoves(&moveList);
        self.getRookMoves(&moveList);
        self.getBishopMoves(&moveList);

        return moveList;
    }

    pub fn format(
        self: Self,
        writer: *std.Io.Writer,
    ) std.Io.Writer.Error!void {
        for (0..BoardSize) |r| {
            try writer.print("{} | ", .{BoardSize - r});
            for (0..BoardSize) |file| {
                const rank = BoardSize - r - 1;
                var ch: u8 = '-';

                const mask: u64 = @as(u64, 1) << @as(u6, @intCast(8 * rank + file));

                if ((self.pieces[Color.White][PieceType.Pawn] & mask) > 0) {
                    ch = 'P';
                } else if ((self.pieces[Color.White][PieceType.Rook] & mask) > 0) {
                    ch = 'R';
                } else if ((self.pieces[Color.White][PieceType.Knight] & mask) > 0) {
                    ch = 'N';
                } else if ((self.pieces[Color.White][PieceType.Bishop] & mask) > 0) {
                    ch = 'B';
                } else if ((self.pieces[Color.White][PieceType.Queen] & mask) > 0) {
                    ch = 'Q';
                } else if ((self.pieces[Color.White][PieceType.King] & mask) > 0) {
                    ch = 'K';
                } else if ((self.pieces[Color.Black][PieceType.Pawn] & mask) > 0) {
                    ch = 'p';
                } else if ((self.pieces[Color.Black][PieceType.Rook] & mask) > 0) {
                    ch = 'r';
                } else if ((self.pieces[Color.Black][PieceType.Knight] & mask) > 0) {
                    ch = 'n';
                } else if ((self.pieces[Color.Black][PieceType.Bishop] & mask) > 0) {
                    ch = 'b';
                } else if ((self.pieces[Color.Black][PieceType.Queen] & mask) > 0) {
                    ch = 'q';
                } else if ((self.pieces[Color.Black][PieceType.King] & mask) > 0) {
                    ch = 'k';
                }

                try writer.print("{c} ", .{ch});
            }
            try writer.print("\n", .{});

            if (r == BoardSize - 1) {
                try writer.print("    ", .{});
                for (0..BoardSize) |_| {
                    try writer.print("--", .{});
                }
                try writer.print("\n", .{});

                try writer.print("    ", .{});
                for (0..BoardSize) |f| {
                    try writer.print("{c} ", .{'A' + @as(u8, @intCast(f))});
                }
                try writer.print("\n", .{});
            }
        }
    }
};
