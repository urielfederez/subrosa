const constants = @import("../constants.zig");
const Mask = constants.Mask;
const core = @import("../core.zig");
const Color = core.Color;
const Bitboard = core.Bitboard;
const BoardSize = core.BoardSize;

pub const knight_moves: [BoardSize * BoardSize]Bitboard = blk: {
    var moves: [BoardSize * BoardSize]Bitboard = undefined;

    for (0..BoardSize) |y| {
        for (0..BoardSize) |x| {
            moves[y * BoardSize + x] = 0;

            if (x < BoardSize - 2 and y < BoardSize - 1) {
                moves[y * BoardSize + x] |= Mask.mask(x + 2, y + 1);
            }
            if (x < BoardSize - 2 and y > 0) {
                moves[y * BoardSize + x] |= Mask.mask(x + 2, y - 1);
            }
            if (x > 1 and y < BoardSize - 1) {
                moves[y * BoardSize + x] |= Mask.mask(x - 2, y + 1);
            }
            if (x > 1 and y > 0) {
                moves[y * BoardSize + x] |= Mask.mask(x - 2, y - 1);
            }

            if (x < BoardSize - 1 and y < BoardSize - 2) {
                moves[y * BoardSize + x] |= Mask.mask(x + 1, y + 2);
            }
            if (x > 0 and y < BoardSize - 2) {
                moves[y * BoardSize + x] |= Mask.mask(x - 1, y + 2);
            }
            if (x < BoardSize - 1 and y > 1) {
                moves[y * BoardSize + x] |= Mask.mask(x + 1, y - 2);
            }
            if (x > 0 and y > 1) {
                moves[y * BoardSize + x] |= Mask.mask(x - 1, y - 2);
            }
        }
    }

    break :blk moves;
};
