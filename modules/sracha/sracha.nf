process SRACHA_GET {
    tag "${meta.id}"
    label 'process_low'

    container 'community.wave.seqera.io/library/sracha:0.3.6--61ed6f22f3229db0'

    input:
    tuple val(meta), val(accession)

    output:
    tuple val(meta), path('*.fastq.gz'), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    sracha get --output-dir sracha --split split-files --threads ${task.cpus} --connections ${task.cpus} --yes ${args} ${accession}
    mv sracha/*.fastq.gz "${prefix}.fastq.gz"
    """
}
