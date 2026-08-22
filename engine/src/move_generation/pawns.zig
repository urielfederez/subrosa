const constants = @import("../constants.zig");
const Mask = constants.Mask;
const core = @import("../core.zig");
const Color = core.Color;
const Bitboard = core.Bitboard;
const BoardSize = core.BoardSize;

pub const pawn_moves: [Color.All][BoardSize * BoardSize]Bitboard = blk: {
    var moves: [Color.All][BoardSize * BoardSize]Bitboard = undefined;

    // For each color, for every square position, there should be a bitboard
    // with bits set based on where a pawn at that position can move
    // Note that this includes:
    //      - first move rule to move by 2

    for (0..BoardSize - 1) |y| {
        for (0..BoardSize) |x| {
            moves[Color.Black][y * BoardSize + x] = 0;
            moves[Color.White][y * BoardSize + x] = 0;

            if (y > 1) {
                moves[Color.Black][y * BoardSize + x] |= Mask.mask(x, y - 1);
            }
            if (y == 6) {
                moves[Color.Black][y * BoardSize + x] |= Mask.mask(x, y - 2);
            }

            if (y == 1) {
                moves[Color.White][y * BoardSize + x] |= Mask.mask(x, y + 2);
            }
            moves[Color.White][y * BoardSize + x] |= Mask.mask(x, y + 1);
        }
    }

    // NOTE: promotion is not handled yet
    break :blk moves;
};

pub const pawn_attacks: [Color.All][BoardSize * BoardSize]Bitboard = blk: {
    var attacks: [Color.All][BoardSize * BoardSize]Bitboard = undefined;

    // For each color, for every square position, there should be a bitboard
    // with bits set based on where a pawn at that position can move
    // Note that this includes:
    //      - first move rule to move by 2

    for (0..BoardSize) |y| {
        for (0..BoardSize) |x| {
            attacks[Color.White][y * BoardSize + x] = Mask.mask(x, y);
            attacks[Color.Black][y * BoardSize + x] = Mask.mask(x, y);
        }
    }

    // NOTE: promotion is not handled yet
    break :blk attacks;
};
