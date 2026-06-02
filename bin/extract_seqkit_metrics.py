#!/usr/bin/env python3
import argparse
import csv

from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description='Extract simple metrics from seqkit stats TSV.')
    parser.add_argument('seqkit_stats', type=Path)

    args = parser.parse_args()

    simulated_reads = 0
    total_bases = 0
    weighted_quality = 0.0

    with args.seqkit_stats.open() as handle:
        for row in csv.DictReader(handle, delimiter='\t'):
            reads = int(row['num_seqs'])
            bases = int(row['sum_len'])
            avg_quality = float(row['AvgQual'])

            simulated_reads += reads
            total_bases += bases
            weighted_quality += avg_quality * bases

    if total_bases == 0:
        print(f'{simulated_reads}\tnull')
    else:
        print(f'{simulated_reads}\t{weighted_quality / total_bases:.2f}')


if __name__ == '__main__':
    main()
