process RASUSA_READS {
    tag "${meta.id}"
    label 'process_low'

    container 'community.wave.seqera.io/library/rasusa:4.1.0--ea51c4058561e458'

    input:
    tuple val(meta), path(reads)
    val bases

    output:
    tuple val(meta), path("*.subsampled.fastq.gz"), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    rasusa reads --bases ${bases} ${args} ${reads} -o "${prefix}.subsampled.fastq.gz"
    """
}
