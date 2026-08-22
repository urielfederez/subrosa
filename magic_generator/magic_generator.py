import json
import logging

from .bishop_precomputation import (
    precompute_occupancy_and_attacks as precompute_bishop_occupancy_and_attacks,
)
from .rook_precomputation import (
    precompute_occupancy_and_attacks as precompute_rook_occupancy_and_attacks,
)
from .search import search_magics

logger = logging.getLogger(__name__)
logging.basicConfig(encoding="utf-8", level=logging.DEBUG)


def main():
    bishop_precomputation = precompute_bishop_occupancy_and_attacks()
    bishop_magics, bishop_idx_to_attack = search_magics(
        seed=0, precomputation=bishop_precomputation
    )

    rook_precomputation = precompute_rook_occupancy_and_attacks()
    rook_magics, rook_idx_to_attack = search_magics(
        seed=0, precomputation=rook_precomputation
    )

    # serialize to JSON files (for now, optimize to binary files later)
    with open("rook_magics.json", "w") as output_file:
        data = {
            "magics": rook_magics,
            "mapping": rook_idx_to_attack,
        }
        output_file.write(json.dumps(data))


if __name__ == "__main__":
    main()
