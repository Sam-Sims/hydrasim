#!/usr/bin/env python3
import argparse
import csv
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "stats_files",
        nargs="+",
        type=Path,
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    stats_files = sorted(args.stats_files, key=lambda path: path.name)

    fieldnames = []
    rows = []
    for stats_path in stats_files:
        with stats_path.open(newline="") as f:
            reader = csv.DictReader(f, delimiter="\t")
            for field in reader.fieldnames:
                if field not in fieldnames:
                    fieldnames.append(field)
            rows.extend(reader)

    writer = csv.DictWriter(
        sys.stdout, fieldnames=fieldnames, delimiter="\t", restval=""
    )
    writer.writeheader()
    writer.writerows(rows)


if __name__ == "__main__":
    main()
