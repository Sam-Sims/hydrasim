process FASTQ_DUMP {
    tag "$meta.id"
    label 'process_low'

    container 'biocontainers/sra-tools:2.7.0--0'


    input:
    tuple val(meta), val(accession)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    prefetch ${accession}
    fastq-dump \
        --outdir . \
        --gzip \
        ${args} \
        */*.sra
    """
}
