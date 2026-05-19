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


def write_file(path: Path, writer: csv.writer, write_header: bool) -> None:
    with path.open(newline="") as f:
        reader = csv.reader(f, delimiter="\t")
        header = next(reader)

        if write_header:
            writer.writerow(header)

        writer.writerows(reader)


def main() -> None:
    args = parse_args()
    stats_files = sorted(args.stats_files, key=lambda path: path.name)

    writer = csv.writer(sys.stdout, delimiter="\t")
    for i, stats_path in enumerate(stats_files):
        write_file(stats_path, writer, i == 0)


if __name__ == "__main__":
    main()
