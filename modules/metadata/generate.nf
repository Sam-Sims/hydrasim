process GENERATE_METADATA {
    label 'process_single'

    container 'community.wave.seqera.io/library/python:3.12.13--27a817c2c0890658'

    input:
    path(metadata_records)
    val hydrasim_version

    output:
    path('metadata.csv'), emit: csv

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    generate_metadata.py \
        --hydrasim-version "${hydrasim_version}" \
        ${args} \
        ${metadata_records} \
        > metadata.csv
    """
}
