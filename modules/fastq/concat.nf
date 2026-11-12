process FASTQ_CONCAT {
    tag "${meta.id}"
    label 'process_single'

    container 'ubuntu:24.04'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.fastq.gz'), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cat ${args} ${reads} > "${prefix}.fastq.gz"
    """
}
