# hydrasim

*Hybrid metagenome simulator.*

## Background
Hydrasim takes reference genomes (FASTA), background datasets (FASTQ), simulates spike-in reads and mixes them into the background to create mock metagenomic datasets (FASTQ).

This fork has diverged from upstream quite a bit to fit my use case, in quite breaking ways.

In brief:

- all supplied references are spiked into all supplied FASTQ datasets at all supplied coverages
- split into nf-core lite™ modules and subworkflows for readability and better module reuse/optional modules
- background FASTQ downsampling with Rasusa has been made optional via `--downsample_background false`
- adds containers for all modules and updates them to all use seqera wave containers
- replaces `sra-tools` downloads with `sracha` (sra-tools was segfaulting for whatever reason)
- separates Badread whole-reference and adds a forced per-segment simulation strategies
  - This is useful for small segmented genomes at low coverage where not each segment would otherwise be sampled
- Adds seqkit stats to get stats for simulated reads
- Outputs simulated reads only as a seperate output as well as full dataset
- Adds an option to run badread with smaller lengths below a defined "low coverage" thereshold
  - This is useful for small segmented genomes where reads would otherwise span the entire length of the segment and you only want partial coverage
- Automatic metadata generation ready for upload straight to synthscape
- can tag simulated reads to find them later
- can add a seed to badread for deterministic generation

## How to use

Only tested with `nextflow version 25.10.4 build 11173`

tldr

```bash
nextflow run sam-sims/hydrasim \
  -profile docker \
  --reference_csv references.csv \
  --dataset_csv datasets.csv
```

This runs with sensible defaults: coverages `0.1x,1x,10x,100x`, background downsampling on to `10k` bases, Badread for single-end inputs, wgsim for paired inputs, metadata off, simulated read tagging off.

The design is a full cross product - every reference is spiked into every dataset at every requested coverage.

Typically if uploading to synthscape you might enable some extra features:

```bash
nextflow run sam-sims/hydrasim \
  -profile docker \
  --reference_csv references.csv \
  --dataset_csv datasets.csv \
  --generate_metadata true \
  --tag_simulated_reads true
```
Or you can run the test profile:

```bash
nextflow run sam-sims/hydrasim -profile test
```

### Input files

Reference CSV:

```csv
id,accession,path,taxon_id
reference_1,,reference_1.fasta,12345
```

`taxon_id` is optional, but include it if you want `metadata.csv` to populate `spiked_ids` for upload.

Dataset CSV:

```csv
id,layout,accession,source_climb_id,reads_1,reads_2
ERR123456789,single,,,ERR123456789.fastq.gz,
ERR987654321,paired,,,ERR987654321_1.fastq.gz,ERR987654321_2.fastq.gz
ERR555555555,single,ERR555555555,,,
```

For references and datasets, provide one source per row, either an accession or local files. 

If `accession` is set Hydrasim downloads it. If local paths are set, leave `accession` blank. 

`source_climb_id` is optional and is only populated in the output `metadata.csv` when provided.

Reference accessions are downloaded with NCBI Datasets. Dataset accessions are downloaded with `sracha`.

### Background downsampling

By default background FASTQs are downsampled before simulated reads are mixed in. Use `--dataset_coverage` to set the target passed to Rasusa, e.g. `10k`. Use `--downsample_background false` to keep the full input background reads.

### Low coverage Badread length override

Badread can generate reads longer than small viral segments. At low spikein coverage this can give unhelpful simulations where a read spans most/all of a segment, or where segmented references are poorly represented. Use the low-coverage override to switch to shorter Badread lengths at or below a coverage threshold:

```bash
--badread_per_segment true
--badread_low_coverage_cutoff 0.1
--badread_low_coverage_length 400,100
```

With that example, coverages `<= 0.1x` use `--length 400,100` and higher coverages use `--badread_length`. `--badread_per_segment true` runs Badread separately for each FASTA record, then concatenates the segment reads. This is useful for segmented references where low total coverage might otherwise sample only one segment, or miss short segments entirely.

### Tagged simulated reads

Use `--tag_simulated_reads true` to modify simulated read IDs before they are mixed with background reads. Badread reads get `_badread` wgsim reads get `_wgsim`. This makes simulated reads queryable after upload/ingest. Background read IDs are not changed.

### Badread seed

Badread is random by default. Set `--badread_seed` if you want deterministic Badread output for repeat runs:

```bash
--badread_seed 11
```

Leave it unset if you want fresh simulated reads each run.

### Metadata generation

Use `--generate_metadata true` to write `metadata.csv` for upload. The CSV is built from the final full FASTQ outputs. Hydrasim details go into the `methods` JSON field: simulator, reference ID, coverage, simulator parameters, simulated read count, and simulated average quality.

### Seqkit stats

Hydrasim runs `seqkit stats` on the simulated reads before background mixing. Per-sample stats are written under `<ref>/<dataset>/simulated/` and all simulated stats are combined into top-level `simulated_summary.tsv`. This is useful to get an idea of read length and Q score of simulated reads.

### Outputs

- `<ref>/<dataset>/simulated/` simulated reads only + seqkit stats
- `<ref>/<dataset>/full/` simulated reads mixed with background reads
- `simulated_summary.tsv` combined seqkit summary
- `metadata.csv` if `--generate_metadata true`
