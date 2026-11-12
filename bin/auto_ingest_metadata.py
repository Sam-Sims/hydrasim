#!/usr/bin/env python3
import argparse
import csv
import os
import tempfile

import boto3
from botocore.config import Config

parser = argparse.ArgumentParser()
parser.add_argument("metadata_csv")
args = parser.parse_args()

bucket = os.environ["HYDRASIM_UPLOAD_BUCKET"]
s3_config = Config(retries={"total_max_attempts": 3, "mode": "standard"})
s3 = boto3.client("s3", config=s3_config, endpoint_url="https://s3.climb.ac.uk")

with open(args.metadata_csv, newline="") as f:
    rows = list(csv.DictReader(f))

for row in rows:
    # same naming scheme as eesi synthscape.<run_index>.<run_id>.{csv,fastq.gz}
    basename = f"synthscape.{row['run_index']}.{row['run_id']}"
    csv_name = f"{basename}.csv"
    reads_name = f"{basename}.fastq.gz"
    columns = [col for col, value in row.items() if value and col != "r1"]

    with tempfile.TemporaryDirectory() as tempdir:
        csv_path = os.path.join(tempdir, csv_name)
        with open(csv_path, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=columns)
            writer.writeheader()
            writer.writerow({col: row[col] for col in columns})

        s3.upload_file(csv_path, bucket, csv_name)
        print(f"Uploaded {csv_name} to {bucket}")

    s3.upload_file(os.path.basename(row["r1"]), bucket, reads_name)
    print(f"Uploaded {reads_name} to {bucket}")
