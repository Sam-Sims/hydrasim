process METADATA_RECORD {
    tag "$meta.id"
    label 'process_single'

    container 'ubuntu:24.04'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path('*.metadata.json'), emit: metadata

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix         = task.ext.prefix ?: "${meta.id}"
    def reads_dir      = task.ext.reads_dir ?: '.'
    def badread_length = meta.badread_length != null ? "\"${meta.badread_length}\"" : 'null'
    def ref_taxon_id   = meta.ref_taxon_id != null ? meta.ref_taxon_id : 'null'

    """
    read_files=( ${reads} )
    r1=\$(basename "\${read_files[0]}")

    cat > "${prefix}.metadata.json" <<EOF
    {
      "dataset_id": "${meta.id}",
      "ref_id": "${meta.ref_id}",
      "single_end": ${meta.single_end},
      "coverage": "${meta.coverage}",
      "badread_length": ${badread_length},
      "ref_taxon_id": ${ref_taxon_id},
      "reads": "${reads_dir}/\${r1}"
    }
    EOF
    """
}
