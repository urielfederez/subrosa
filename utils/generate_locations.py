def main():
    print("===============")
    print("mask")
    for rank in range(8):
        rank_mask = 0xFF << (rank * 8)
        for file in range(8):
            mask = 1 << (rank * 8 + file)
            print(f"pub const {chr(ord('A') + file)}{rank + 1} = 0x{mask:016x};")

        print(f"pub const Rank{rank+1} = 0x{rank_mask:016x};")

    print("===============")
    print("index")
    for rank in range(8):
        rank_mask = 0xFF << (rank * 8)
        for file in range(8):
            idx = rank * 8 + file
            print(f"pub const {chr(ord('A') + rank)}{file + 1} = {idx};")


if __name__ == "__main__":
    main()
