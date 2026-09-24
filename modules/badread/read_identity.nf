process BADREAD_READ_IDENTITY {
    tag "$meta.id"
    label 'process_single'

    container 'community.wave.seqera.io/library/python:3.12.13--27a817c2c0890658'

    input:
    tuple val(meta), path(reads), path(stats, stageAs: 'input.tsv')

    output:
    tuple val(meta), path("*.seqkit_stats.tsv"), emit: tsv

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}.simulated"

    """
    add_badread_identity.py \
        ${stats} \
        > "${prefix}.seqkit_stats.tsv"
    """
}
