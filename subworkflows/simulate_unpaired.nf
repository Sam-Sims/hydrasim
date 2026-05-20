include { RASUSA_READS                                     } from '../modules/rasusa/reads'
include { SIMULATE_BADREAD_WHOLE_REFERENCE                } from './simulate_badread_whole_reference'
include { SIMULATE_BADREAD_PER_SEGMENT                    } from './simulate_badread_per_segment'
include { FASTQ_CONCAT as FASTQ_CONCAT_BACKGROUND         } from '../modules/fastq/concat'
include { SEQKIT_STATS                                    } from '../modules/seqkit/stats'

workflow SIMULATE_UNPAIRED {
    take:
    ch_recipes
    val_downsample_background
    val_dataset_coverage
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

    SEQKIT_STATS(ch_spike_reads)

    ch_spike_reads
        .join(ch_background_reads)
        .map { meta, spike_reads, base_reads -> tuple(meta, [spike_reads, base_reads], '') }
        .set { ch_concat_reads }

    FASTQ_CONCAT_BACKGROUND(ch_concat_reads)

    emit:
    reads           = FASTQ_CONCAT_BACKGROUND.out.reads
    simulated_stats = SEQKIT_STATS.out.tsv
}
