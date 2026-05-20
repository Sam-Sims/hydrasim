process FASTQ_CONCAT {
    tag "$meta.id"
    label 'process_single'

    container 'ubuntu:24.04'

    input:
    tuple val(meta), path(spike_reads), path(base_reads)

    output:
    tuple val(meta), path("*.fastq.gz"), emit: reads

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    if [[ "${meta.single_end}" == "true" ]]; then
        cat ${spike_reads} ${base_reads} > "${prefix}.fastq.gz"
    else
        cat ${spike_reads[0]} ${base_reads[0]} > "${prefix}_R1.fastq.gz"
        cat ${spike_reads[1]} ${base_reads[1]} > "${prefix}_R2.fastq.gz"
    fi
    """
}
