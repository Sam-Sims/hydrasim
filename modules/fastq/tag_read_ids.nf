process FASTQ_TAG_READ_IDS {
    tag "$meta.id"
    label 'process_single'

    container 'community.wave.seqera.io/library/python_pip_pyfastx:42b6d9cd5f680595'

    input:
    tuple val(meta), path(reads, stageAs: 'input.fq.gz'), val(suffix)
    val tag

    output:
    tuple val(meta), path('*.fq.gz'), val(suffix), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    tag_fastq_read_ids.py \
        --tag "${tag}" \
        --output "${prefix}${suffix}.fq.gz" \
        ${args} \
        ${reads}
    """
}
