#!/usr/bin/env nextflow

include { validateParameters } from 'plugin/nf-schema'
include { HYDRASIM } from './workflows/hydrasim'

workflow {
    validateParameters()

    HYDRASIM(
        file(params.reference_csv, type: 'file'),
        file(params.dataset_csv, type: 'file'),
        channel.fromList(params.coverages),
        params.downsample_background,
        params.dataset_coverage,
        params.badread_per_segment,
        params.badread_length,
        params.badread_low_coverage_cutoff,
        params.badread_low_coverage_length,
        params.wgsim_length_read1,
        params.wgsim_length_read2
    )
}
