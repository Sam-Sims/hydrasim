process SEQKIT_STATS {
    tag "${meta.id}"
    label 'process_single'

    container 'community.wave.seqera.io/library/seqkit:2.13.0--05c0a96bf9fb2751'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.seqkit_stats.tsv"), emit: tsv

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    seqkit stats --all --tabular ${args} ${reads} > "${prefix}.seqkit_stats.tsv"
    """
}
