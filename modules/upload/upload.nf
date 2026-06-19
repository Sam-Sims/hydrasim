process UPLOAD {
    label 'process_single'

    container 'community.wave.seqera.io/library/python_pip_boto3:d936f6a9177e3faf'

    input:
    path metadata_csv
    path upload_reads

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    auto_ingest_metadata.py ${metadata_csv}
    """
}
