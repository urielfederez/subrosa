import logging
import random

logger = logging.getLogger(__name__)


def generate_rook_attack_bitboard(occupancy: int, file: int, rank: int) -> int:
    bitboard = 0

    curr_file = file + 1
    while curr_file < 8:
        bit_index = rank * 8 + curr_file
        if (occupancy & (1 << bit_index)) > 0:
            break
        bitboard |= 1 << bit_index
        curr_file += 1

    curr_file = file - 1
    while curr_file >= 0:
        bit_index = rank * 8 + curr_file
        if (occupancy & (1 << bit_index)) > 0:
            break
        bitboard |= 1 << bit_index
        curr_file -= 1

    curr_rank = rank + 1
    while curr_rank < 8:
        bit_index = curr_rank * 8 + file
        if (occupancy & (1 << bit_index)) > 0:
            break
        bitboard |= 1 << bit_index
        curr_rank += 1

    curr_rank = rank - 1
    while curr_rank >= 0:
        bit_index = curr_rank * 8 + file
        if (occupancy & (1 << bit_index)) > 0:
            break
        bitboard |= 1 << bit_index
        curr_rank -= 1

    return bitboard


def print_bitboard(bitboard: int):
    for y in range(8):
        for x in range(8):
            bit = bitboard & (1 << ((8 - y - 1) * 8 + x))
            print(f"{'X' if bit > 0 else '-'}", end=" ")
        print()


def main():
    # Rook magics
    for rank in range(8):
        for file in range(8):
            print(f"Determining rook magic for {chr(ord('A') + file)}{rank+1}")

            num_occupancy_lower_files = max(file - 1, 0)
            num_occupancy_upper_files = max(8 - file - 2, 0)
            num_occupancy_lower_ranks = max(rank - 1, 0)
            num_occupancy_upper_ranks = max(8 - rank - 2, 0)

            num_occupancy_bits = (
                num_occupancy_upper_files
                + num_occupancy_lower_files
                + num_occupancy_lower_ranks
                + num_occupancy_upper_ranks
            )

            has_found_valid_magic = False

            while not has_found_valid_magic:
                magic = random.randint(0, (1 << 64) - 1)

                index_to_attack_bitboard = {}
                has_found_valid_magic = True

                for idx in range(2**num_occupancy_bits):
                    bitboard = 0
                    bit_idx = 0

                    # Populate bitboard
                    for i in range(num_occupancy_lower_ranks):
                        bit_value = (idx & (1 << bit_idx)) >> bit_idx
                        bitboard |= bit_value << ((rank - 1 - i) * 8 + file)
                        bit_idx += 1

                    for i in range(num_occupancy_upper_files):
                        bit_value = (idx & (1 << bit_idx)) >> bit_idx
                        bitboard |= bit_value << (rank * 8 + (file + 1 + i))
                        bit_idx += 1

                    for i in range(num_occupancy_lower_files):
                        bit_value = (idx & (1 << bit_idx)) >> bit_idx
                        bitboard |= bit_value << (rank * 8 + (file - 1 - i))
                        bit_idx += 1

                    for i in range(num_occupancy_upper_ranks):
                        bit_value = (idx & (1 << bit_idx)) >> bit_idx
                        bitboard |= bit_value << ((rank + 1 + i) * 8 + file)
                        bit_idx += 1

                    assert bit_idx == num_occupancy_bits

                    # Generate attack bitboard
                    attack = generate_rook_attack_bitboard(bitboard, file, rank)

                    index = (bitboard * magic) & ((1 << 64) - 1)
                    index = index >> (64 - num_occupancy_bits)

                    if (
                        index in index_to_attack_bitboard
                        and index_to_attack_bitboard[index] != attack
                    ):
                        has_found_valid_magic = False
                        logger.warning(
                            f"Non-unique index found: ({idx}) {index} -> already stored as {index_to_attack_bitboard[index]} but has attack {attack}"
                        )
                        break

                    logger.info(
                        f"Populated index at ({idx}) with magic index {index} as {attack}"
                    )
                    index_to_attack_bitboard[index] = attack

            if has_found_valid_magic:
                print(f"valid magic: 0x{magic:016x}")


if __name__ == "__main__":
    main()
