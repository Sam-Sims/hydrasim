#!/usr/bin/env python3
import argparse
import gzip
from pathlib import Path
import pyfastx


def tagged_read_id(read_id: str, tag: str) -> str:
    fields = read_id.split(maxsplit=1)
    read_id = fields[0]
    description = fields[1] if len(fields) == 2 else ""

    for mate_suffix in ("/1", "/2"):
        if read_id.endswith(mate_suffix):
            tagged_id = f"{read_id[: -len(mate_suffix)]}{tag}{mate_suffix}"
            break
    else:
        tagged_id = f"{read_id}{tag}"

    if not description:
        return tagged_id

    description = "|".join(description.replace(",", " ").split())
    return f"{tagged_id}|{description}"


def main() -> None:
    parser = argparse.ArgumentParser(description="Append a tag to FASTQ read IDs.")
    parser.add_argument("--tag", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("fastq", type=Path)

    args = parser.parse_args()

    output_path = args.output
    temporary_output_path = output_path.with_name(f".{output_path.name}.tmp")

    with gzip.open(temporary_output_path, "wt") as output:
        for name, sequence, quality in pyfastx.Fastq(
            str(args.fastq),
            build_index=False,
            full_name=True,
        ):
            output.write(f"@{tagged_read_id(name, args.tag)}\n")
            output.write(f"{sequence}\n")
            output.write("+\n")
            output.write(f"{quality}\n")

    temporary_output_path.replace(output_path)


if __name__ == "__main__":
    main()
