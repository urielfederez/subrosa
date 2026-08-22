import random


def generate_64bit_magic():
    return random.randint(0, (1 << 64) - 1) & ((1 << 64) - 1)
