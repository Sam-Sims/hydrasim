process SEQKIT_STATS {
    tag "$meta.id"
    label 'process_single'

    container 'community.wave.seqera.io/library/seqkit:2.13.0--05c0a96bf9fb2751'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.seqkit_stats.tsv"), emit: tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}.simulated"

    """
    seqkit stats \
        --all \
        --tabular \
        ${args} \
        ${reads} \
        > "${prefix}.seqkit_stats.tsv"
    """
}
