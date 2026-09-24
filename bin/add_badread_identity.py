#!/usr/bin/env python3
import csv
import gzip
import re
import sys


def main() -> None:
    with open(sys.argv[1], newline="") as f:
        reader = csv.DictReader(f, delimiter="\t")
        writer = csv.DictWriter(
            sys.stdout,
            fieldnames=reader.fieldnames + ["mean_read_identity"],
            delimiter="\t",
        )
        writer.writeheader()

        for row in reader:
            total = 0.0
            count = 0

            with gzip.open(row["file"], "rt") as fastq:
                ## be gone biopython
                for i, line in enumerate(fastq):
                    if i % 4 == 0:
                        match = re.search(r"read_identity=([0-9.]+)%", line)
                        if match:
                            total += float(match.group(1))
                            count += 1

            row["mean_read_identity"] = f"{total / count:.2f}" if count else ""
            writer.writerow(row)


if __name__ == "__main__":
    main()
