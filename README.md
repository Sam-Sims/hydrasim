# hydrasim

Hybrid metagenome simulator

Fork changes a few things:

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
