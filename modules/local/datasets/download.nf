process NCBI_DATASETS_DOWNLOAD_GENOME {
    tag "$meta.id"
    label 'process_low'

    container 'community.wave.seqera.io/library/ncbi-datasets-cli_unzip:ec913708564558ae'

    input:
    tuple val(meta), val(accession)

    output:
    tuple val(meta), path("*.fna"), emit: fasta

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    datasets download genome accession ${accession} ${args}
    unzip -o ncbi_dataset.zip
    output="\$(readlink -f ncbi_dataset/data/*/*_genomic.fna)"
    mv "\${output}" "${prefix}.fna"
    """
}
