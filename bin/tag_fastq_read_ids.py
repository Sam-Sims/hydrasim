#!/usr/bin/env python3
import argparse
import gzip
from pathlib import Path
import pyfastx


def tagged_read_id(read_id: str, tag: str) -> str:
    for mate_suffix in ('/1', '/2'):
        if read_id.endswith(mate_suffix):
            return f'{read_id[:-len(mate_suffix)]}{tag}{mate_suffix}'

    return f'{read_id}{tag}'


def main() -> None:
    parser = argparse.ArgumentParser(description='Append a tag to FASTQ read IDs.')
    parser.add_argument('--tag', required=True)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('fastq', type=Path)

    args = parser.parse_args()

    output_path = args.output
    temporary_output_path = output_path.with_name(f'.{output_path.name}.tmp')

    with gzip.open(temporary_output_path, 'wt') as output:
        for name, sequence, quality in pyfastx.Fastq(str(args.fastq), build_index=False):
            output.write(f'@{tagged_read_id(name, args.tag)}\n')
            output.write(f'{sequence}\n')
            output.write('+\n')
            output.write(f'{quality}\n')

    temporary_output_path.replace(output_path)


if __name__ == '__main__':
    main()
