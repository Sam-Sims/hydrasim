include { BADREAD_SIMULATE as BADREAD_SIMULATE_SEGMENT } from '../modules/badread/simulate'
include { FASTQ_CONCAT as FASTQ_CONCAT_SEGMENTS        } from '../modules/fastq/concat'

workflow SIMULATE_BADREAD_PER_SEGMENT {
    take:
    ch_simulation_inputs

    main:
    ch_simulation_inputs
        .splitFasta(by: 1, elem: 1, file: true)
        .map { meta, segment_fasta, coverage ->
            def segment_meta = meta + [
                segment_id: segment_fasta.baseName
            ]

            tuple(segment_meta, segment_fasta, coverage)
        }
        .set { ch_segment_badread_inputs }

    BADREAD_SIMULATE_SEGMENT(ch_segment_badread_inputs)

    BADREAD_SIMULATE_SEGMENT.out.reads
        .map { meta, reads ->
            def recipe_meta = meta.findAll { key, _value -> key != 'segment_id' }
            tuple(recipe_meta, reads)
        }
        .groupTuple()
        .map { meta, reads -> tuple(meta, reads, '_simulated') }
        .set { ch_segment_read_lists }

    FASTQ_CONCAT_SEGMENTS(ch_segment_read_lists)

    emit:
    reads = FASTQ_CONCAT_SEGMENTS.out.reads
}
