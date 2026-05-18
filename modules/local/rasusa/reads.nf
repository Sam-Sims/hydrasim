process RASUSA_READS {
    tag "$meta.id"
    label 'process_low'

    container 'biocontainers/rasusa:2.0.0--h715e4b3_2'

    input:
    tuple val(meta), path(reads)
    val bases

    output:
    tuple val(meta), path("*.subsampled.fastq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args       = task.ext.args ?: ''
    def prefix     = task.ext.prefix ?: "${meta.id}"
    def output_args = meta.single_end ? "-o ${prefix}.subsampled.fastq.gz" : "-o ${prefix}_1.subsampled.fastq.gz -o ${prefix}_2.subsampled.fastq.gz"

    """
    rasusa reads \
        --bases ${bases} \
        ${args} \
        ${reads} \
        ${output_args}
    """
}
