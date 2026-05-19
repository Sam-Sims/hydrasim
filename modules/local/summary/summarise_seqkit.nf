process SUMMARISE_SEQKIT {
    label 'process_single'

    container 'community.wave.seqera.io/library/python:3.12.13--27a817c2c0890658'

    input:
    path stats_files

    output:
    path "simulated_summary.tsv", emit: tsv

    script:
    """
    summarise_reads.py \
        ${stats_files} \
        > simulated_summary.tsv
    """
}
