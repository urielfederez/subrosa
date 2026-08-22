const std = @import("std");

pub const Bitboard = u64;
pub const BoardSize = 8;
pub const PieceType = struct {
    pub const Pawn = 0;
    pub const Rook = 1;
    pub const Knight = 2;
    pub const Bishop = 3;
    pub const Queen = 4;
    pub const King = 5;
    pub const All = 6;
};

pub const Color = struct {
    pub const Black = 0;
    pub const White = 1;
    pub const All = 2;
};

pub fn printBitboard(board: Bitboard) void {
    for (0..8) |r| {
        std.debug.print("{} | ", .{8 - r});
        for (0..8) |file| {
            const rank = 8 - r - 1;
            var ch: u8 = '-';

            const mask: u64 = @as(u64, 1) << @as(u6, @intCast(8 * rank + file));

            if ((board & mask) > 0) {
                ch = 'X';
            }

            std.debug.print("{c} ", .{ch});
        }
        std.debug.print("\n", .{});

        if (r == 7) {
            std.debug.print("    ", .{});
            for (0..8) |_| {
                std.debug.print("--", .{});
            }
            std.debug.print("\n", .{});

            std.debug.print("    ", .{});
            for (0..8) |f| {
                std.debug.print("{c} ", .{'A' + @as(u8, @intCast(f))});
            }
            std.debug.print("\n", .{});
        }
    }
}
