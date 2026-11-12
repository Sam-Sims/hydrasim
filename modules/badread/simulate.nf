process BADREAD_SIMULATE {
    tag "${meta.id}"
    label 'process_low'

    container 'community.wave.seqera.io/library/badread:0.4.2--681703784fcb5155'

    input:
    tuple val(meta), path(fasta), val(coverage)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    badread simulate --reference ${fasta} --quantity ${coverage}x ${args} | gzip -c > "${prefix}.fastq.gz"
    """
}
