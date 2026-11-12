include { NCBI_DATASETS_DOWNLOAD_GENOME } from '../modules/datasets/download'
include { SRACHA_GET                    } from '../modules/sracha/sracha'
include { RASUSA_READS                  } from '../modules/rasusa/reads'
include { SIMULATE_SPIKE_IN             } from '../subworkflows/simulate_spike_in'
include { GENERATE_METADATA             } from '../modules/metadata/generate'
include { UPLOAD                        } from '../modules/upload/upload'

workflow HYDRASIM {
    take:
    ch_reference_rows // channel: [ val(meta: [id, accession, taxon_id, study_id]), path(fasta) ]
    ch_dataset_rows // channel: [ val(meta: [id, accession, source_climb_id]), path(reads) ]
    ch_coverages // channel: val(coverage: Float)
    val_downsample_background
    val_downsample_bases
    val_tag_simulated_reads
    val_badread_per_segment
    val_badread_length
    val_badread_low_coverage_cutoff
    val_badread_low_coverage_length
    val_generate_metadata
    val_auto_ingest

    main:

    // prep refs
    ch_reference_downloads = ch_reference_rows
        .filter { meta, _fasta -> meta.accession }
        .map { meta, _fasta -> tuple(meta, meta.accession) }

    NCBI_DATASETS_DOWNLOAD_GENOME(ch_reference_downloads)

    ch_references = ch_reference_rows
        .filter { _meta, fasta -> fasta }
        .mix(NCBI_DATASETS_DOWNLOAD_GENOME.out.fasta)

    // prep fastqs
    ch_dataset_downloads = ch_dataset_rows
        .filter { meta, _reads -> meta.accession }
        .map { meta, _reads -> tuple(meta, meta.accession) }

    SRACHA_GET(ch_dataset_downloads)

    ch_datasets = ch_dataset_rows
        .filter { _meta, reads -> reads }
        .mix(SRACHA_GET.out.reads)

    if (val_downsample_background) {
        RASUSA_READS(ch_datasets, val_downsample_bases)
        ch_backgrounds = RASUSA_READS.out.reads
    }
    else {
        ch_backgrounds = ch_datasets
    }

    // prep recipes
    ch_recipes = ch_references
        .combine(ch_coverages)
        .combine(ch_backgrounds)
        .map { ref_meta, ref_fasta, coverage, dataset_meta, reads ->
            def badread_length = coverage <= val_badread_low_coverage_cutoff
                ? val_badread_low_coverage_length
                : val_badread_length

            def meta = [
                id: "${ref_meta.id}_${dataset_meta.id}_${coverage}x",
                dataset_id: dataset_meta.id,
                ref_id: ref_meta.id,
                coverage: coverage,
                badread_length: badread_length,
                ref_taxon_id: ref_meta.taxon_id,
                ref_study_id: ref_meta.study_id,
                accession: dataset_meta.accession,
                source_climb_id: dataset_meta.source_climb_id,
            ]

            tuple(meta, ref_fasta, coverage, reads)
        }

    // simulate
    SIMULATE_SPIKE_IN(
        ch_recipes,
        val_tag_simulated_reads,
        val_badread_per_segment,
    )

    ch_summary = SIMULATE_SPIKE_IN.out.simulated_stats
        .map { _meta, stats -> stats }
        .collectFile(
            name: 'simulated_summary.tsv',
            keepHeader: true,
            sort: { stats -> stats.name },
        )

    ch_metadata = channel.empty()

    if (val_generate_metadata) {
        ch_metadata_records = SIMULATE_SPIKE_IN.out.reads
            .join(SIMULATE_SPIKE_IN.out.simulated_stats)
            .map { meta, reads, stats ->
                // the metadata script needs a million inputs so they are jsonified (into jsonl) first
                groovy.json.JsonOutput.toJson(
                    [dataset_id: meta.dataset_id, source_climb_id: meta.source_climb_id, accession: meta.accession, ref_id: meta.ref_id, coverage: meta.coverage, badread_length: meta.badread_length, ref_taxon_id: meta.ref_taxon_id, study_id: meta.ref_study_id, reads: "${workflow.outputDir}/${meta.ref_id}/${meta.dataset_id}/full/${reads.name}", stats: stats.name]
                )
            }
            .collectFile(name: 'metadata_records.jsonl', newLine: true, sort: true)

        ch_metadata_stats = SIMULATE_SPIKE_IN.out.simulated_stats
            .map { _meta, stats -> stats }
            .collect()

        GENERATE_METADATA(
            ch_metadata_records,
            ch_metadata_stats,
            workflow.manifest.version,
        )
        ch_metadata = GENERATE_METADATA.out.csv

        if (val_auto_ingest) {
            ch_upload_reads = SIMULATE_SPIKE_IN.out.reads
                .map { _meta, reads -> reads }
                .collect()

            UPLOAD(
                GENERATE_METADATA.out.csv,
                ch_upload_reads,
            )
        }
    }

    emit:
    reads           = SIMULATE_SPIKE_IN.out.reads // channel: [ val(meta), path(fastq.gz) ]
    simulated_reads = SIMULATE_SPIKE_IN.out.simulated_reads // channel: [ val(meta), path(fastq.gz) ]
    simulated_stats = SIMULATE_SPIKE_IN.out.simulated_stats // channel: [ val(meta), path(seqkit_stats.tsv) ]
    summary         = ch_summary // channel: path(simulated_summary.tsv)
    metadata        = ch_metadata // channel: path(metadata.csv)
}
