#!/usr/bin/env nextflow

include { validateParameters ; samplesheetToList } from 'plugin/nf-schema'
include { HYDRASIM           } from './workflows/hydrasim'

// the params are all defined in main so they can be typed and removes the need for casting them later
// atm I cant find a way to type params in a config and tbh not really clear what nf-core guidance is here
// so here they all are for now
params {
    // inputs
    reference_csv: Path
    dataset_csv: Path
    store_dir: String = 'store'
    // simulation opts
    coverages: String = '0.1,1,10,100'
    // opt in to downsampling each background dataset with rasusa before spiking
    downsample_background: Boolean = false
    // if enabled - total bases to downsample each background dataset to
    downsample_bases: String = '10k'
    // if enabled append a _badread tag to simulated read IDs for later identification
    tag_simulated_reads: Boolean = false
    // badread parameters (set to badread defaults)
    badread_length: String = '15000,13000'
    badread_identity: String = '95,99,2.5'
    badread_error_model: String = 'nanopore2023'
    badread_qscore_model: String = 'nanopore2023'
    badread_junk_reads: Integer = 1
    badread_random_reads: Integer = 1
    badread_chimeras: Integer = 1
    badread_glitches: String = '10000,25,25'
    // seed for badread (if wanting deterministic output)
    badread_seed: Integer? = null
    // run badread on every record in the input fasta (useful to force outputs for segmented genomes at low coverage levels)
    badread_per_segment: Boolean = false
    // the cutoff to apply badread_low_coverage_length (0 disables)
    badread_low_coverage_cutoff: Float = 0
    // different badread length settings to apply to any coverages at or below badread_low_coverage_cutoff
    badread_low_coverage_length: String = '400,100'
    // metadata deafultsp
    generate_metadata: Boolean = false
    auto_ingest: Boolean = false
    metadata_sample_source: String = 'other'
    metadata_sample_type: String = 'other'
    metadata_governance_status: String = 'no_consent_for_research'
    metadata_input_type: String = 'validation_material'
    metadata_spike_in: String = 'none'
    metadata_received_date: String? = null
}

workflow {

    main:
    validateParameters()

    HYDRASIM(
        channel.fromList(samplesheetToList(params.reference_csv, "${projectDir}/assets/schema_reference.json")),
        channel.fromList(samplesheetToList(params.dataset_csv, "${projectDir}/assets/schema_dataset.json")),
        channel.fromList(params.coverages.tokenize(',').collect { coverage -> coverage.trim().toFloat() }),
        params.downsample_background,
        params.downsample_bases,
        params.tag_simulated_reads,
        params.badread_per_segment,
        params.badread_length,
        params.badread_low_coverage_cutoff,
        params.badread_low_coverage_length,
        params.generate_metadata,
        params.auto_ingest,
    )

    publish:
    reads           = HYDRASIM.out.reads
    simulated_reads = HYDRASIM.out.simulated_reads
    simulated_stats = HYDRASIM.out.simulated_stats
    summary         = HYDRASIM.out.summary
    metadata        = HYDRASIM.out.metadata
}

output {
    reads {
        path { meta, _reads -> "${meta.ref_id}/${meta.dataset_id}/full" }
    }
    simulated_reads {
        path { meta, _reads -> "${meta.ref_id}/${meta.dataset_id}/simulated" }
    }
    simulated_stats {
        path { meta, _stats -> "${meta.ref_id}/${meta.dataset_id}/simulated" }
    }
    summary {
    }
    metadata {
    }
}
