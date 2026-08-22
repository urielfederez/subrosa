import logging
from dataclasses import dataclass

from .search import BasePrecomputationResult
from .utils import (
    board_squares,
    create_mask,
    get_bit_value,
)

logger = logging.getLogger(__name__)


def generate_bishop_attack_bitboard(occupancy: int, file: int, rank: int) -> int:
    bitboard = 0

    # Lower right quadrant
    curr_file = file + 1
    curr_rank = rank - 1

    while curr_rank >= 0 and curr_file < 8:
        mask = create_mask(curr_file, curr_rank)
        bitboard |= mask

        if (occupancy & mask) > 0:
            break

        curr_rank -= 1
        curr_file += 1

    # Lower left quadrant
    curr_file = file - 1
    curr_rank = rank - 1

    while curr_rank >= 0 and curr_file >= 0:
        mask = create_mask(curr_file, curr_rank)
        bitboard |= mask

        if (occupancy & mask) > 0:
            break

        curr_rank -= 1
        curr_file -= 1

    # upper right quadrant
    curr_file = file + 1
    curr_rank = rank + 1

    while curr_rank < 8 and curr_file < 8:
        mask = create_mask(curr_file, curr_rank)
        bitboard |= mask

        if (occupancy & mask) > 0:
            break

        curr_rank += 1
        curr_file += 1

    # upper left quadrant
    curr_file = file - 1
    curr_rank = rank + 1

    while curr_rank < 8 and curr_file >= 0:
        mask = create_mask(curr_file, curr_rank)
        bitboard |= mask

        if (occupancy & mask) > 0:
            break

        curr_rank += 1
        curr_file -= 1

    return bitboard


@dataclass
class BishopPrecomputationResult(BasePrecomputationResult):
    num_squares_lower_right_quad: int
    num_squares_lower_left_quad: int
    num_squares_upper_left_quad: int
    num_squares_upper_right_quad: int

    @property
    def num_occupancy_bits(self):
        return (
            self.num_squares_lower_left_quad
            + self.num_squares_lower_right_quad
            + self.num_squares_upper_left_quad
            + self.num_squares_upper_right_quad
        )


def precompute_occupancy_and_attacks() -> list[BishopPrecomputationResult]:
    precomputed_occupancy_and_attack: list[BishopPrecomputationResult] = []

    for square in board_squares():
        num_occupancy_lower_files = max(square.file - 1, 0)
        num_occupancy_upper_files = max(8 - square.file - 2, 0)
        num_occupancy_lower_ranks = max(square.rank - 1, 0)
        num_occupancy_upper_ranks = max(8 - square.rank - 2, 0)

        result = BishopPrecomputationResult(
            num_squares_lower_right_quad=min(
                num_occupancy_upper_files, num_occupancy_lower_ranks
            ),
            num_squares_lower_left_quad=min(
                num_occupancy_lower_files, num_occupancy_lower_ranks
            ),
            num_squares_upper_left_quad=min(
                num_occupancy_lower_files, num_occupancy_upper_ranks
            ),
            num_squares_upper_right_quad=min(
                num_occupancy_upper_files, num_occupancy_upper_ranks
            ),
            occupancy_and_attack_bitboards=[],
        )

        for idx in range(2**result.num_occupancy_bits):
            bitboard = 0
            bit_idx = 0

            for i in range(result.num_squares_lower_right_quad):
                assert (square.rank - 1 - i) >= 0
                assert (square.file + 1 + i) < 8
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= (
                    create_mask(square.file + 1 + i, square.rank - 1 - i) * bit_value
                )

                bit_idx += 1

            for i in range(result.num_squares_lower_left_quad):
                assert (square.rank - 1 - i) >= 0
                assert (square.file - 1 - i) >= 0
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= (
                    create_mask(square.file - 1 - i, square.rank - 1 - i) * bit_value
                )

                bit_idx += 1

            for i in range(result.num_squares_upper_right_quad):
                assert (square.rank + 1 + i) < 8
                assert (square.file + 1 + i) < 8
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= (
                    create_mask(square.file + 1 + i, square.rank + 1 + i) * bit_value
                )

                bit_idx += 1

            for i in range(result.num_squares_upper_left_quad):
                assert (square.rank + 1 + i) < 8
                assert (square.file - 1 - i) >= 0
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= (
                    create_mask(square.file - 1 - i, square.rank + 1 + i) * bit_value
                )

                bit_idx += 1

            attack = generate_bishop_attack_bitboard(bitboard, square.file, square.rank)
            result.occupancy_and_attack_bitboards.append((bitboard, attack))

            assert bit_idx == result.num_occupancy_bits

        assert (
            len(result.occupancy_and_attack_bitboards) == 2**result.num_occupancy_bits
        ), f"{2**result.num_occupancy_bits}, {len(result.occupancy_and_attack_bitboards)}"

        precomputed_occupancy_and_attack.append(result)

    return precomputed_occupancy_and_attack
