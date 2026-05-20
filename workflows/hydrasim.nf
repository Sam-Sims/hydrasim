include { NCBI_DATASETS_DOWNLOAD_GENOME } from '../modules/datasets/download'
include { SRACHA_GET                  } from '../modules/sracha/sracha'
include { SIMULATE_UNPAIRED          } from '../subworkflows/simulate_unpaired'
include { SIMULATE_PAIRED            } from '../subworkflows/simulate_paired'
include { SUMMARISE_SEQKIT           } from '../modules/summary/summarise_seqkit'

workflow HYDRASIM {
    take:
    val_reference_csv
    val_dataset_csv
    ch_coverages
    val_downsample_background
    val_dataset_coverage
    val_badread_per_segment
    val_badread_length
    val_badread_low_coverage_cutoff
    val_badread_low_coverage_length
    val_wgsim_length_read1
    val_wgsim_length_read2

    main:

    // prep refs
    channel
        .fromPath(val_reference_csv)
        .splitCsv(header: true)
        .map { row ->
            def id        = "${row.id}".trim()
            def accession = row.accession ? "${row.accession}".trim() : ''
            def fasta     = row.path ? file("${row.path}".trim(), checkIfExists: true) : []
            def meta      = [
                id: id
            ]
            tuple(meta, accession, fasta)
        }
        .branch { meta, accession, fasta ->
            local: fasta
                return tuple(meta, fasta)
            download: accession
                return tuple(meta, accession)
        }
        .set { reference_rows }

    NCBI_DATASETS_DOWNLOAD_GENOME(reference_rows.download)

    reference_rows.local
        .mix(NCBI_DATASETS_DOWNLOAD_GENOME.out.fasta)
        .set { ch_references }

    // prep fastqs
    channel
        .fromPath(val_dataset_csv)
        .splitCsv(header: true)
        .map { row ->
            def id        = "${row.id}".trim()
            def layout    = "${row.layout}".trim()
            def accession = row.accession ? "${row.accession}".trim() : ''
            def reads1    = row.reads_1 ? file("${row.reads_1}".trim(), checkIfExists: true) : []
            def reads2    = row.reads_2 ? file("${row.reads_2}".trim(), checkIfExists: true) : []
            def meta      = [
                id        : id,
                single_end: layout == 'single'
            ]

            tuple(meta, accession, reads1, reads2)
        }
        .branch { meta, accession, reads1, reads2 ->
            local: reads1
                return tuple(meta, meta.single_end ? reads1 : [reads1, reads2])
            download: accession
                return tuple(meta, accession)
        }
        .set { dataset_rows }

    SRACHA_GET(dataset_rows.download)

    dataset_rows.local
        .mix(SRACHA_GET.out.reads)
        .set { ch_datasets }

    // prep recipies
    ch_references
        .combine(ch_coverages)
        .combine(ch_datasets)
        .map { ref_meta, ref_fasta, coverage, dataset_meta, reads ->
            def meta      = [
                id        : dataset_meta.id,
                ref_id    : ref_meta.id,
                single_end: dataset_meta.single_end,
                coverage  : coverage
            ]

            tuple(meta, ref_fasta, coverage, reads)
        }
        .branch { meta, ref_fasta, coverage, reads ->
            paired: !meta.single_end
                return tuple(meta, ref_fasta, coverage, reads)
            unpaired: meta.single_end
                return tuple(meta, ref_fasta, coverage, reads)
        }
        .set { recipes }

    recipes.unpaired
        .map { meta, ref_fasta, coverage, reads ->
            def selected_badread_length = val_badread_length

            if (
                val_badread_low_coverage_length &&
                val_badread_low_coverage_cutoff != null &&
                (coverage as BigDecimal) <= (val_badread_low_coverage_cutoff as BigDecimal)
            ) {
                selected_badread_length = val_badread_low_coverage_length
            }

            tuple(meta + [badread_length: selected_badread_length], ref_fasta, coverage, reads)
        }
        .set { ch_unpaired_recipes }

    // simulate
    SIMULATE_UNPAIRED(
        ch_unpaired_recipes,
        val_downsample_background,
        val_dataset_coverage,
        val_badread_per_segment
    )

    SIMULATE_PAIRED(
        recipes.paired,
        val_downsample_background,
        val_dataset_coverage,
        val_wgsim_length_read1,
        val_wgsim_length_read2
    )

    SIMULATE_PAIRED.out.simulated_stats
        .mix(SIMULATE_UNPAIRED.out.simulated_stats)
        .set { ch_simulated_stats }

    ch_simulated_stats
        .map { _meta, stats -> stats }
        .collect()
        .set { ch_simulated_stats_files }

    SUMMARISE_SEQKIT(ch_simulated_stats_files)

    emit:
    paired          = SIMULATE_PAIRED.out.reads
    unpaired        = SIMULATE_UNPAIRED.out.reads
    simulated_stats = ch_simulated_stats
    summary         = SUMMARISE_SEQKIT.out.tsv
}
