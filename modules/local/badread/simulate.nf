process BADREAD_SIMULATE {
    tag "$meta.id"
    label 'process_low'

    container 'biocontainers/badread:0.4.1--pyhdfd78af_0'

    input:
    tuple val(meta), path(fasta), val(coverage)

    output:
    tuple val(meta), path("*.fq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    badread simulate \
        --reference ${fasta} \
        --quantity ${coverage}x \
        ${args} \
        | gzip -c > "${prefix}.fq.gz"
    """
}
