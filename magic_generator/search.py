import logging
import random
from abc import ABC, abstractmethod
from dataclasses import dataclass

from .utils import (
    board_squares,
    generate_64bit_magic,
)

logger = logging.getLogger(__name__)


@dataclass
class BasePrecomputationResult(ABC):
    occupancy_and_attack_bitboards: list[tuple[int, int]]

    @property
    @abstractmethod
    def num_occupancy_bits(self):
        pass


def search_magics(
    *,
    seed: int | None = None,
    precomputation: list[BasePrecomputationResult],
) -> tuple[list[int], list[dict[int, int]]]:
    random.seed(seed)

    magic_values: list[int] = []
    square_to_mapping: list[dict[int, int]] = []

    for square in board_squares():
        logger.info(f"Determining magic for {square.name}")

        has_found_valid_magic = False
        num_candidates_tried = 0

        while not has_found_valid_magic:
            # Sparse random numbers empirically tend to result in faster searches
            magic = (
                generate_64bit_magic() & generate_64bit_magic() & generate_64bit_magic()
            )
            num_candidates_tried += 1
            result = precomputation[square.index]

            index_to_attack_bitboard: dict[int, int] = {}
            has_found_valid_magic = True

            for bitboard, attack in result.occupancy_and_attack_bitboards:
                index = (bitboard * magic) & ((1 << 64) - 1)
                index = index >> (64 - result.num_occupancy_bits)

                assert index < (1 << result.num_occupancy_bits)

                if (
                    index in index_to_attack_bitboard
                    and index_to_attack_bitboard[index] != attack
                ):
                    has_found_valid_magic = False
                    break

                index_to_attack_bitboard[index] = attack

        if has_found_valid_magic:
            logger.info(
                f"valid magic found for {square.name}: 0x{magic:016x}; tried {num_candidates_tried} candidates"
            )
            magic_values.append(magic)
            square_to_mapping.append(index_to_attack_bitboard)

    return magic_values, square_to_mapping
