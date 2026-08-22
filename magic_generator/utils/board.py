from dataclasses import dataclass


@dataclass
class Square:
    rank: int
    file: int
    name: str

    @property
    def index(self):
        return self.rank * 8 + self.file


def board_squares():
    for rank in range(8):
        for file in range(8):
            name = f"{chr(ord('A') + file)}{rank+1}"
            yield Square(rank, file, name)


def print_bitboard(bitboard: int):
    for y in range(8):
        for x in range(8):
            bit = bitboard & (1 << ((8 - y - 1) * 8 + x))
            print(f"{'X' if bit > 0 else '-'}", end=" ")
        print()
