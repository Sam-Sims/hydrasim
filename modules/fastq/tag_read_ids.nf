process FASTQ_TAG_READ_IDS {
    tag "${meta.id}"
    label 'process_single'

    container 'community.wave.seqera.io/library/python:3.12.13--27a817c2c0890658'

    input:
    tuple val(meta), path(reads, stageAs: 'input.fastq.gz')
    val tag

    output:
    tuple val(meta), path('*.fastq.gz'), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    tag_fastq_read_ids.py --tag "${tag}" --output "${prefix}.fastq.gz" ${args} ${reads}
    """
}
