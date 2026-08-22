import logging
from dataclasses import dataclass

from .search import BasePrecomputationResult
from .utils import (
    board_squares,
    create_mask,
    get_bit_value,
)

logger = logging.getLogger(__name__)


@dataclass
class SquarePrecomputationResult(BasePrecomputationResult):
    num_occupancy_lower_files: int
    num_occupancy_upper_files: int
    num_occupancy_lower_ranks: int
    num_occupancy_upper_ranks: int

    @property
    def num_occupancy_bits(self):
        return (
            self.num_occupancy_lower_files
            + self.num_occupancy_upper_files
            + self.num_occupancy_lower_ranks
            + self.num_occupancy_upper_ranks
        )


def generate_rook_attack_bitboard(occupancy: int, file: int, rank: int) -> int:
    bitboard = 0

    curr_file = file + 1
    while curr_file < 8:
        bit_index = rank * 8 + curr_file
        bitboard |= 1 << bit_index
        if (occupancy & (1 << bit_index)) > 0:
            break
        curr_file += 1

    curr_file = file - 1
    while curr_file >= 0:
        bit_index = rank * 8 + curr_file
        bitboard |= 1 << bit_index
        if (occupancy & (1 << bit_index)) > 0:
            break
        curr_file -= 1

    curr_rank = rank + 1
    while curr_rank < 8:
        bit_index = curr_rank * 8 + file
        bitboard |= 1 << bit_index
        if (occupancy & (1 << bit_index)) > 0:
            break
        curr_rank += 1

    curr_rank = rank - 1
    while curr_rank >= 0:
        bit_index = curr_rank * 8 + file
        bitboard |= 1 << bit_index
        if (occupancy & (1 << bit_index)) > 0:
            break
        curr_rank -= 1

    return bitboard


def precompute_occupancy_and_attacks() -> list[SquarePrecomputationResult]:

    precomputed_occupancy_and_attack: list[SquarePrecomputationResult] = []

    for square in board_squares():
        result = SquarePrecomputationResult(
            num_occupancy_lower_files=max(square.file - 1, 0),
            num_occupancy_upper_files=max(8 - square.file - 2, 0),
            num_occupancy_lower_ranks=max(square.rank - 1, 0),
            num_occupancy_upper_ranks=max(8 - square.rank - 2, 0),
            occupancy_and_attack_bitboards=[],
        )

        for idx in range(2**result.num_occupancy_bits):
            bitboard = 0
            bit_idx = 0

            # Populate bitboard
            for i in range(result.num_occupancy_lower_ranks):
                assert (square.rank - 1 - i) >= 0
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= create_mask(square.file, (square.rank - 1 - i)) * bit_value
                bit_idx += 1

            for i in range(result.num_occupancy_upper_files):
                assert (square.file + 1 + i) < 8
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= create_mask(square.file + i + 1, square.rank) * bit_value
                bit_idx += 1

            for i in range(result.num_occupancy_lower_files):
                assert (square.file - 1 - i) >= 0
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= create_mask(square.file - i - 1, square.rank) * bit_value
                bit_idx += 1

            for i in range(result.num_occupancy_upper_ranks):
                assert (square.rank + 1 + i) < 8
                bit_value = get_bit_value(idx, bit_idx)
                bitboard |= create_mask(square.file, square.rank + i + 1) * bit_value
                bit_idx += 1

            assert bit_idx == result.num_occupancy_bits

            attack = generate_rook_attack_bitboard(bitboard, square.file, square.rank)
            result.occupancy_and_attack_bitboards.append((bitboard, attack))

        assert (
            len(result.occupancy_and_attack_bitboards) == 2**result.num_occupancy_bits
        ), f"{2**result.num_occupancy_bits}, {len(result.occupancy_and_attack_bitboards)}"

        precomputed_occupancy_and_attack.append(result)

    return precomputed_occupancy_and_attack
