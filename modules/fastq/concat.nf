process FASTQ_CONCAT {
    tag "$meta.id"
    label 'process_single'

    container 'ubuntu:24.04'

    input:
    tuple val(meta), path(reads), val(suffix)

    output:
    tuple val(meta), path('*.fastq.gz'), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cat ${args} ${reads} > "${prefix}${suffix}.fastq.gz"
    """
}
