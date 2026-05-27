include { RASUSA_READS                                     } from '../modules/rasusa/reads'
include { WGSIM_WGSIM                                      } from '../modules/wgsim/wgsim'
include { FASTQ_CONCAT as FASTQ_CONCAT_BACKGROUND          } from '../modules/fastq/concat'
include { METADATA_RECORD                                  } from '../modules/metadata/record'
include { SEQKIT_STATS                                     } from '../modules/seqkit/stats'

workflow SIMULATE_PAIRED {
    take:
    ch_recipes
    val_downsample_background
    val_dataset_coverage
    val_wgsim_length_read1
    val_wgsim_length_read2

    main:
    ch_recipes
        .map { meta, _ref_fasta, _coverage, reads -> tuple(meta, reads) }
        .set { ch_base_reads }

    ch_recipes
        .map { meta, ref_fasta, coverage, _reads -> tuple(meta, ref_fasta, coverage) }
        .set { ch_simulation_inputs }

    if (val_downsample_background) {
        RASUSA_READS(ch_base_reads, val_dataset_coverage)
        ch_background_reads = RASUSA_READS.out.reads
    } else {
        ch_background_reads = ch_base_reads
    }

    WGSIM_WGSIM(ch_simulation_inputs, val_wgsim_length_read1, val_wgsim_length_read2)

    WGSIM_WGSIM.out.reads
        .map { meta, reads1, reads2 -> tuple(meta, [reads1, reads2]) }
        .set { ch_simulated_reads }

    SEQKIT_STATS(ch_simulated_reads)

    ch_simulated_reads
        .join(ch_background_reads)
        .flatMap { meta, spike_reads, base_reads ->
            [
                tuple(meta, [spike_reads[0], base_reads[0]], '_R1'),
                tuple(meta, [spike_reads[1], base_reads[1]], '_R2')
            ]
        }
        .set { ch_concat_reads }

    FASTQ_CONCAT_BACKGROUND(ch_concat_reads)

    FASTQ_CONCAT_BACKGROUND.out.reads
        .groupTuple()
        .set { ch_reads }

    ch_reads
        .join(SEQKIT_STATS.out.tsv)
        .set { ch_metadata_record_inputs }

    METADATA_RECORD(ch_metadata_record_inputs)

    emit:
    reads           = ch_reads
    metadata        = METADATA_RECORD.out.metadata
    simulated_stats = SEQKIT_STATS.out.tsv
}
