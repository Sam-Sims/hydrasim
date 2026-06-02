include { RASUSA_READS                                     } from '../modules/rasusa/reads'
include { SIMULATE_BADREAD_WHOLE_REFERENCE                } from './simulate_badread_whole_reference'
include { SIMULATE_BADREAD_PER_SEGMENT                    } from './simulate_badread_per_segment'
include { FASTQ_CONCAT as FASTQ_CONCAT_BACKGROUND         } from '../modules/fastq/concat'
include { METADATA_RECORD                                 } from '../modules/metadata/record'
include { SEQKIT_STATS                                    } from '../modules/seqkit/stats'
include { FASTQ_TAG_READ_IDS                             } from '../modules/fastq/tag_read_ids'

workflow SIMULATE_UNPAIRED {
    take:
    ch_recipes
    val_downsample_background
    val_dataset_coverage
    val_tag_simulated_reads
    val_badread_per_segment

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

    if (val_badread_per_segment) {
        SIMULATE_BADREAD_PER_SEGMENT(ch_simulation_inputs)
        ch_spike_reads = SIMULATE_BADREAD_PER_SEGMENT.out.reads
    } else {
        SIMULATE_BADREAD_WHOLE_REFERENCE(ch_simulation_inputs)
        ch_spike_reads = SIMULATE_BADREAD_WHOLE_REFERENCE.out.reads
    }

    if (val_tag_simulated_reads) {
        ch_spike_reads
            .map { meta, reads -> tuple(meta, reads, '') }
            .set { ch_tag_read_inputs }

        FASTQ_TAG_READ_IDS(ch_tag_read_inputs, '_badread')

        FASTQ_TAG_READ_IDS.out.reads
            .map { meta, reads, _suffix -> tuple(meta, reads) }
            .set { ch_simulated_reads }
    } else {
        ch_simulated_reads = ch_spike_reads
    }

    SEQKIT_STATS(ch_simulated_reads)

    ch_simulated_reads
        .join(ch_background_reads)
        .map { meta, spike_reads, base_reads -> tuple(meta, [spike_reads, base_reads], '') }
        .set { ch_concat_reads }

    FASTQ_CONCAT_BACKGROUND(ch_concat_reads)

    FASTQ_CONCAT_BACKGROUND.out.reads
        .join(SEQKIT_STATS.out.tsv)
        .set { ch_metadata_record_inputs }

    METADATA_RECORD(ch_metadata_record_inputs)

    emit:
    reads           = FASTQ_CONCAT_BACKGROUND.out.reads
    metadata        = METADATA_RECORD.out.metadata
    simulated_stats = SEQKIT_STATS.out.tsv
}
