include { BADREAD_SIMULATE as BADREAD_SIMULATE_WHOLE_REFERENCE } from '../modules/badread/simulate'
include { SIMULATE_BADREAD_PER_SEGMENT                         } from './simulate_badread_per_segment'
include { FASTQ_CONCAT as FASTQ_CONCAT_BACKGROUND              } from '../modules/fastq/concat'
include { SEQKIT_STATS                                         } from '../modules/seqkit/stats'
include { FASTQ_TAG_READ_IDS                                   } from '../modules/fastq/tag_read_ids'
include { BADREAD_READ_IDENTITY                                } from '../modules/badread/read_identity'

workflow SIMULATE_SPIKE_IN {
    take:
    ch_recipes // channel: [ val(meta), path(ref_fasta), val(coverage), path(background_reads) ]
    val_tag_simulated_reads
    val_badread_per_segment

    main:
    ch_simulation_inputs = ch_recipes.map { meta, ref_fasta, coverage, _reads -> tuple(meta, ref_fasta, coverage) }
    ch_backgrounds = ch_recipes.map { meta, _ref_fasta, _coverage, reads -> tuple(meta, reads) }

    if (val_badread_per_segment) {
        SIMULATE_BADREAD_PER_SEGMENT(ch_simulation_inputs)
        ch_spike_reads = SIMULATE_BADREAD_PER_SEGMENT.out.reads
    }
    else {
        BADREAD_SIMULATE_WHOLE_REFERENCE(ch_simulation_inputs)
        ch_spike_reads = BADREAD_SIMULATE_WHOLE_REFERENCE.out.reads
    }

    if (val_tag_simulated_reads) {
        FASTQ_TAG_READ_IDS(ch_spike_reads, '_badread')
        ch_simulated_reads = FASTQ_TAG_READ_IDS.out.reads
    }
    else {
        ch_simulated_reads = ch_spike_reads
    }

    SEQKIT_STATS(ch_simulated_reads)

    ch_read_identity_inputs = ch_simulated_reads.join(SEQKIT_STATS.out.tsv)

    BADREAD_READ_IDENTITY(ch_read_identity_inputs)

    ch_concat_reads = ch_simulated_reads
        .join(ch_backgrounds)
        .map { meta, spike_reads, base_reads -> tuple(meta, [spike_reads, base_reads]) }

    FASTQ_CONCAT_BACKGROUND(ch_concat_reads)

    emit:
    reads           = FASTQ_CONCAT_BACKGROUND.out.reads // channel: [ val(meta), path(fastq.gz) ]
    simulated_reads = ch_simulated_reads // channel: [ val(meta), path(fastq.gz) ]
    simulated_stats = BADREAD_READ_IDENTITY.out.tsv // channel: [ val(meta), path(seqkit_stats.tsv) ]
}
