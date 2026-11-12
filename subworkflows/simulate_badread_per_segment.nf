include { BADREAD_SIMULATE as BADREAD_SIMULATE_SEGMENT } from '../modules/badread/simulate'
include { FASTQ_CONCAT as FASTQ_CONCAT_SEGMENTS        } from '../modules/fastq/concat'

workflow SIMULATE_BADREAD_PER_SEGMENT {
    take:
    ch_simulation_inputs

    main:
    ch_segment_badread_inputs = ch_simulation_inputs.flatMap { meta, fasta, coverage ->
        def segments = fasta.splitFasta(by: 1, file: true)
        segments.collect { segment -> tuple(groupKey(meta, segments.size()), segment, coverage) }
    }

    BADREAD_SIMULATE_SEGMENT(ch_segment_badread_inputs)

    ch_segment_read_lists = BADREAD_SIMULATE_SEGMENT.out.reads
        .groupBy()
        .map { key, reads -> tuple(key.getGroupTarget(), reads.toSorted { segment_reads -> segment_reads.name }) }

    FASTQ_CONCAT_SEGMENTS(ch_segment_read_lists)

    emit:
    reads = FASTQ_CONCAT_SEGMENTS.out.reads
}
