process FASTQ_DUMP {
    tag "$meta.id"
    label 'process_low'

    container 'community.wave.seqera.io/library/sra-tools:3.4.1--191c884ef112e97b'


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
