#!/usr/bin/env python3
import argparse
import csv
import os
import shutil
import tempfile


import boto3
from botocore.config import Config

parser = argparse.ArgumentParser()
parser.add_argument('metadata_csv')
args = parser.parse_args()

bucket = os.environ['HYDRASIM_UPLOAD_BUCKET']
s3_config = Config(retries={'total_max_attempts': 3, 'mode': 'standard'})
s3 = boto3.client('s3', config=s3_config, endpoint_url='https://s3.climb.ac.uk')

with open(args.metadata_csv, newline='') as f:
    reader = csv.DictReader(f)
    rows = list(reader)
    columns = reader.fieldnames

records = {}
for row in rows:
    records.setdefault(row['run_index'], []).append(row)

file_control_cols = {
    'r1',
    'r1_upload_name',
    'csv_name',
}

cols_for_upload = [
    col for col in columns
    if col not in file_control_cols
]

for run_idx, run_rows in records.items():
    with tempfile.TemporaryDirectory() as tempdir:
        outfilename = os.path.join(tempdir, run_rows[0]['csv_name'])

        r1_in_filename = os.path.basename(run_rows[0]['r1'])
        r1_upload_name = os.path.join(tempdir, run_rows[0]['r1_upload_name'])

        cols_to_write = [
            col for col in cols_for_upload
            if any(row[col] for row in run_rows)
        ]

        with open(outfilename, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=cols_to_write)
            writer.writeheader()
            writer.writerows({col: row[col] for col in cols_to_write} for row in run_rows)

        shutil.copyfile(r1_in_filename, r1_upload_name)

        for filename in [outfilename, r1_upload_name]:
            s3.upload_file(
                filename,
                bucket,
                os.path.basename(filename),
            )
            print(f'Uploaded {filename} to {bucket}')
