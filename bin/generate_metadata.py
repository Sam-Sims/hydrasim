#!/usr/bin/env python3
import argparse
import csv
import json
import sys
import uuid
from datetime import date
from decimal import Decimal
from pathlib import Path


def read_stats(path: Path) -> dict:
    with path.open(newline="") as handle:
        row = next(csv.DictReader(handle, delimiter="\t"))

    identity = row.get("mean_read_identity")
    return {
        "simulated_reads": int(row["num_seqs"]),
        "simulated_avg_qual": (
            round(float(row["AvgQual"]), 2) if int(row["sum_len"]) else None
        ),
        "simulated_mean_read_identity": round(float(identity), 2) if identity else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument("--hydrasim-version", required=True)
    parser.add_argument(
        "--badread-per-segment", action=argparse.BooleanOptionalAction, required=True
    )
    parser.add_argument("--badread-identity", required=True)
    parser.add_argument("--badread-error-model", required=True)
    parser.add_argument("--badread-qscore-model", required=True)
    parser.add_argument("--badread-junk-reads", type=int, required=True)
    parser.add_argument("--badread-random-reads", type=int, required=True)
    parser.add_argument("--badread-chimeras", type=int, required=True)
    parser.add_argument("--badread-glitches", required=True)
    parser.add_argument("--badread-seed")
    parser.add_argument("--badread-low-coverage-cutoff", type=Decimal, required=True)

    parser.add_argument(
        "--downsample-background", action=argparse.BooleanOptionalAction, required=True
    )
    parser.add_argument("--downsample-bases", required=True)

    parser.add_argument("--sample-source", required=True)
    parser.add_argument("--sample-type", required=True)
    parser.add_argument("--governance-status", required=True)
    parser.add_argument("--input-type", required=True)
    parser.add_argument("--spike-in", required=True)
    parser.add_argument("--received-date", default=date.today().isoformat())

    parser.add_argument("metadata_records", type=Path)

    args = parser.parse_args()

    ## expect JSONL file from nextflow
    records = [
        json.loads(line)
        for line in args.metadata_records.read_text().splitlines()
        if line.strip()
    ]
    records.sort(
        key=lambda record: (
            record["ref_id"],
            record["dataset_id"],
            float(record["coverage"]),
        )
    )

    if args.badread_per_segment:
        strategy = "badread_per_segment"
    elif args.badread_low_coverage_cutoff != 0:
        strategy = "badread_default_low_cov"
    else:
        strategy = "badread_default"

    applications = json.dumps([f"hydrasim {args.hydrasim_version}", "badread"])

    writer = csv.DictWriter(
        sys.stdout,
        fieldnames=["run_index", "study_id", "biosample_id", "r1", "spiked_ids", "source_climb_id", "applications", "methods", "input_type", "specimen_type_details", "sample_source", "sample_type", "spike_in", "batch_id", "sequence_purpose", "governance_status", "iso_country", "iso_region", "extraction_enrichment_protocol", "library_protocol", "sequencing_protocol", "bioinformatics_protocol", "dehumanisation_protocol", "run_id", "received_date"],
    )
    writer.writeheader()

    for run_index, record in enumerate(records):
        coverage_label = f"{str(float(record['coverage'])).rstrip('0').rstrip('.')}x"
        stats = read_stats(Path(record["stats"]))

        methods = {
            "hydrasim_strategy": strategy,
            "hydrasim_version": args.hydrasim_version,
            "coverage": coverage_label,
            "reference_id": record["ref_id"],
            "input_accession": record["accession"] or "",
            "simulator": "badread",
            "badread_per_segment": args.badread_per_segment,
            "badread_length": record["badread_length"],
            "badread_identity": args.badread_identity,
            "badread_error_model": args.badread_error_model,
            "badread_qscore_model": args.badread_qscore_model,
            "badread_junk_reads": args.badread_junk_reads,
            "badread_random_reads": args.badread_random_reads,
            "badread_chimeras": args.badread_chimeras,
            "badread_glitches": args.badread_glitches,
            "badread_seed": args.badread_seed,
            "downsample_background": args.downsample_background,
            "downsample_bases": args.downsample_bases,
            **stats,
        }

        run_id = str(uuid.uuid4())
        taxon_id = record["ref_taxon_id"]

        writer.writerow(
            {
                "run_index": run_index,
                "study_id": record["study_id"],
                "biosample_id": run_id,
                "r1": record["reads"],
                "spiked_ids": f"[{taxon_id}]" if taxon_id else "[]",
                "source_climb_id": record["source_climb_id"] or "",
                "applications": applications,
                "methods": json.dumps(methods),
                "input_type": args.input_type,
                "sample_source": args.sample_source,
                "sample_type": args.sample_type,
                "spike_in": args.spike_in,
                "governance_status": args.governance_status,
                "run_id": run_id,
                "received_date": args.received_date,
            }
        )


if __name__ == "__main__":
    main()
