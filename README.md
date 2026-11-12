# hydrasim

*Hybrid metagenome simulator.*

## Background
Hydrasim takes reference genomes (FASTA), background datasets (FASTQ), simulates spike-in reads and mixes them into the background to create mock metagenomic datasets (FASTQ).

This fork has diverged from upstream quite a bit to fit my use case, in quite breaking ways.

In brief:

- does long read only
- all supplied references are spiked into all supplied FASTQ datasets at all supplied coverages
- split into nf-core lite™ modules and subworkflows for readability and better module reuse/optional modules
- background FASTQ downsampling with Rasusa is now opt in via `--downsample_background true`
- adds containers for all modules and updates them to all use seqera wave containers
- replaces `sra-tools` downloads with `sracha` (sra-tools was segfaulting for whatever reason)
- adds forced per-segment simulation strategies
  - This is useful for small segmented genomes at low coverage where not each segment would otherwise be sampled
- Adds seqkit stats to get stats for simulated reads
- At some point a half finished schema was added - so that has been updated and switched to use nf-schema for samplesheets
- Outputs simulated reads only as a seperate output as well as full dataset
- Adds an option to run badread with smaller lengths below a defined "low coverage" thereshold
  - This is useful for small segmented genomes where reads would otherwise span the entire length of the segment and you only want partial coverage
- Automatic metadata generation ready for upload straight to synthscape
- can tag simulated reads to find them later
- can add a seed to badread for deterministic generation

## How to use

Requires Nextflow >= 26.10. Tested only with `26.10.3`

tldr

```bash
nextflow run sam-sims/hydrasim \
  --reference_csv references.csv \
  --dataset_csv datasets.csv
```

This runs with sensible defaults: coverages `0.1x,1x,10x,100x`, background downsampling off.

Every reference is spiked into every dataset at every coverage.

Typically if uploading to synthscape you might enable some extra features to generate the upload metadata for you, and tag the read ids so its obvious which ones came from badread:

```bash
nextflow run sam-sims/hydrasim \
  -profile docker \
  --reference_csv references.csv \
  --dataset_csv datasets.csv \
  --generate_metadata true \
  --tag_simulated_reads true
```
You can run the test profile to ensure the pipeline works - this uses public data:

```bash
nextflow run sam-sims/hydrasim -profile test
```

### Input files

#### Reference CSV

```csv
id,accession,path,taxon_id,study_id
reference_1,,reference_1.fasta,12345,study_a
```

`study_id` is required. It is used as the `study_id` in `metadata.csv` so you can group samples later when ingested.

`taxon_id` is optional, but include it if you want `metadata.csv` to populate `spiked_ids` for upload.

#### Dataset CSV

Hydrasim only supports long read ONT background datasets. For pairedend simulation use upstream Hydrasim.

Hydraim works with either an accession or local file. If `accession` is set Hydrasim downloads it and so DO NOT set a local file in this case and leave empty. The opposite is true if using local paths YOU MUST leave `accession` blank. 

```csv
id,accession,source_climb_id,reads
ERR123456789,,,ERR123456789.fastq.gz
```

`source_climb_id` is optional and is only populated in the output `metadata.csv` when provided.

### Background downsampling

Use `--downsample_background true` to downsample each background dataset once with Rasusa before simulated reads are mixed in. Use `--downsample_bases` to set the total bases passed to Rasusa.

### Low coverage Badread length override

Badread can generate reads longer than small viral segments. At low spikein coverage this can give unhelpful simulations where a read spans most/all of a segment, or where segmented references are poorly represented. Use the low-coverage override to switch to shorter Badread lengths at or below a coverage threshold:

```bash
--badread_per_segment true
--badread_low_coverage_cutoff 0.1
--badread_low_coverage_length 400,100
```

With that example, coverages `<= 0.1x` use `--length 400,100` and higher coverages use `--badread_length`. `--badread_per_segment true` runs Badread separately for each FASTA record, then concatenates the segment reads. This is useful for segmented references where low total coverage might otherwise sample only one segment, or miss short segments entirely.

### Tagged simulated reads

Use `--tag_simulated_reads true` to modify simulated read IDs before they are mixed with background reads. Reads get `_badread` stuck on the end of them. This makes simulated reads easy to find after ingest.

### Badread seed

Badread is random by default. Set `--badread_seed` if you want deterministic Badread output for repeat runs:

```bash
--badread_seed 11
```

Leave it unset if you want fresh simulated reads each run.

### Metadata generation

Use `--generate_metadata true` to write `metadata.csv` that is ready for upload straightaway. The full bad read set of params is included in the methods section.

`metadata.csv` is also ready for eesi, so you can validate and upload it yourself after the run:

```bash
eesi validate synthscape output/metadata.csv
eesi ingest synthscape output/metadata.csv --upload
```

### Seqkit stats

Hydrasim runs `seqkit stats` on the simulated reads before spiking. Stats are written under `<ref>/<dataset>/simulated/` and all simulated stats are combined into top-level `simulated_summary.tsv`. This is useful to get an idea of read length, Q score and identity etc of simulated reads.
