#!/usr/bin/env python3
import argparse
import csv
import json
import sys
import uuid
from datetime import date
from pathlib import Path

COLUMNS = [
    'run_index', 'study_id', 'biosample_id', 'r1', 'spiked_ids',
    'source_climb_id', 'applications', 'methods',
    'input_type', 'specimen_type_details', 'sample_source',
    'sample_type', 'spike_in', 'batch_id', 'sequence_purpose',
    'governance_status', 'iso_country', 'iso_region',
    'extraction_enrichment_protocol', 'library_protocol',
    'sequencing_protocol', 'bioinformatics_protocol',
    'dehumanisation_protocol', 'run_id', 'r1_upload_name',
    'csv_name', 'received_date',
]


def main() -> None:
    parser = argparse.ArgumentParser()

    parser.add_argument('--hydrasim-version', required=True)
    parser.add_argument('--badread-per-segment', action=argparse.BooleanOptionalAction, required=True)
    parser.add_argument('--badread-length', required=True)
    parser.add_argument('--badread-identity', required=True)
    parser.add_argument('--badread-error-model', required=True)
    parser.add_argument('--badread-qscore-model', required=True)
    parser.add_argument('--badread-junk-reads', type=int, required=True)
    parser.add_argument('--badread-random-reads', type=int, required=True)
    parser.add_argument('--badread-chimeras', type=int, required=True)
    parser.add_argument('--badread-glitches', required=True)
    parser.add_argument('--badread-low-coverage-length')

    parser.add_argument('--downsample-background', action=argparse.BooleanOptionalAction, required=True)
    parser.add_argument('--dataset-coverage', required=True)

    parser.add_argument('--wgsim-length-read1', required=True)
    parser.add_argument('--wgsim-length-read2', required=True)
    parser.add_argument('--wgsim-mutation-rate', required=True)
    parser.add_argument('--wgsim-indel-fraction', required=True)

    parser.add_argument('--study-id', required=True)
    parser.add_argument('--sample-source', required=True)
    parser.add_argument('--sample-type', required=True)
    parser.add_argument('--governance-status', required=True)
    parser.add_argument('--input-type', required=True)
    parser.add_argument('--spike-in', required=True)
    parser.add_argument('--received-date', default=date.today().isoformat())

    parser.add_argument('metadata_records', nargs='+', type=Path)

    args = parser.parse_args()

    records = [json.loads(path.read_text()) for path in args.metadata_records]
    records.sort(key=lambda record: (
        record['ref_id'],
        record['dataset_id'],
        float(record['coverage']),
        record['single_end'],
    ))

    writer = csv.DictWriter(sys.stdout, fieldnames=COLUMNS)
    writer.writeheader()

    for run_index, record in enumerate(records):
        if record['single_end']:
            strategy = 'badread_per_segment' if args.badread_per_segment else 'badread_default'
            if (
                args.badread_low_coverage_length
                and record['badread_length'] is not None
                and record['badread_length'] != args.badread_length
            ):
                strategy = f'{strategy}_low_cov'

            simulator = 'badread'
            methods = {
                'hydrasim_strategy': strategy,
                'hydrasim_version': args.hydrasim_version,
                'coverage': f'{str(float(record["coverage"])).rstrip("0").rstrip(".")}x',
                'reference_id': record['ref_id'],
                'input_accession': record['dataset_id'],
                'simulator': simulator,
                'badread_per_segment': args.badread_per_segment,
                'badread_length': record['badread_length'] or args.badread_length,
                'badread_identity': args.badread_identity,
                'badread_error_model': args.badread_error_model,
                'badread_qscore_model': args.badread_qscore_model,
                'badread_junk_reads': args.badread_junk_reads,
                'badread_random_reads': args.badread_random_reads,
                'badread_chimeras': args.badread_chimeras,
                'badread_glitches': args.badread_glitches,
                'downsample_background': args.downsample_background,
                'dataset_coverage': args.dataset_coverage,
                'simulated_reads': record['simulated_reads'],
                'simulated_avg_qual': record['simulated_avg_qual'],
            }
        else:
            strategy = 'wgsim'
            simulator = 'wgsim'
            methods = {
                'hydrasim_strategy': strategy,
                'hydrasim_version': args.hydrasim_version,
                'coverage': f'{str(float(record["coverage"])).rstrip("0").rstrip(".")}x',
                'reference_id': record['ref_id'],
                'input_accession': record['dataset_id'],
                'simulator': simulator,
                'wgsim_length_read1': args.wgsim_length_read1,
                'wgsim_length_read2': args.wgsim_length_read2,
                'wgsim_mutation_rate': args.wgsim_mutation_rate,
                'wgsim_indel_fraction': args.wgsim_indel_fraction,
                'downsample_background': args.downsample_background,
                'dataset_coverage': args.dataset_coverage,
                'simulated_reads': record['simulated_reads'],
                'simulated_avg_qual': record['simulated_avg_qual'],
            }

        run_id = str(uuid.uuid4())
        taxon_id = record['ref_taxon_id']

        writer.writerow({
            'run_index': run_index,
            'study_id': args.study_id,
            'biosample_id': f'{record["dataset_id"]}-{strategy}',
            'r1': record['reads'],
            'spiked_ids': f'[{taxon_id}]' if taxon_id else '[]',
            'source_climb_id': record['dataset_id'],
            'applications': json.dumps([f'hydrasim {args.hydrasim_version}', simulator]),
            'methods': json.dumps(methods),
            'input_type': args.input_type,
            'specimen_type_details': '',
            'sample_source': args.sample_source,
            'sample_type': args.sample_type,
            'spike_in': args.spike_in,
            'batch_id': '',
            'sequence_purpose': '',
            'governance_status': args.governance_status,
            'iso_country': '',
            'iso_region': '',
            'extraction_enrichment_protocol': '',
            'library_protocol': '',
            'sequencing_protocol': '',
            'bioinformatics_protocol': '',
            'dehumanisation_protocol': '',
            'run_id': run_id,
            'r1_upload_name': f'synthscape.{run_index}.{run_id}.fastq.gz',
            'csv_name': f'synthscape.{run_index}.{run_id}.csv',
            'received_date': args.received_date,
        })


if __name__ == '__main__':
    main()
