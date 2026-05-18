process WGSIM_WGSIM {
    tag "$meta.id"
    label 'process_low'

    container 'community.wave.seqera.io/library/wgsim_bc:a72326165be9e21a'

    input:
    tuple val(meta), path(fasta), val(coverage)
    val read_length1
    val read_length2

    output:
    tuple val(meta), path("*_1.fq.gz"), path("*_2.fq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    genome_length=\$(cat ${fasta} | wc -c)
    read_bases=\$(( ${read_length1} + ${read_length2} ))
    num_reads=\$(echo "\$genome_length*${coverage}/\$read_bases" | bc)
    echo "\$genome_length \$num_reads"

    wgsim \
        -N "\${num_reads}" \
        -1 ${read_length1} \
        -2 ${read_length2} \
        ${args} \
        ${fasta} \
        "${prefix}_1.fq" \
        "${prefix}_2.fq"

    gzip "${prefix}_1.fq" "${prefix}_2.fq"
    """
}
