#!/usr/bin/env python3
import argparse
import gzip
from pathlib import Path


def tagged_header(header: str, tag: str) -> str:
    fields = header.split(maxsplit=1)
    tagged_id = f"{fields[0]}{tag}"

    if len(fields) == 1:
        return tagged_id

    description = "|".join(fields[1].replace(",", " ").split())
    return f"{tagged_id}|{description}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("fastq", type=Path)

    args = parser.parse_args()

    ## biopython be gone
    with gzip.open(args.fastq, "rt") as fastq, gzip.open(args.output, "wt") as f:
        for line_number, line in enumerate(fastq):
            if line_number % 4 == 0:
                f.write(f"@{tagged_header(line[1:].rstrip(), args.tag)}\n")
            elif line_number % 4 == 2:
                f.write("+\n")
            else:
                f.write(line)


if __name__ == "__main__":
    main()
