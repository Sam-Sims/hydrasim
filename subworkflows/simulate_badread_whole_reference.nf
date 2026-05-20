include { BADREAD_SIMULATE as BADREAD_SIMULATE_WHOLE_REFERENCE } from '../modules/badread/simulate'

workflow SIMULATE_BADREAD_WHOLE_REFERENCE {
    take:
    ch_simulation_inputs

    main:
    BADREAD_SIMULATE_WHOLE_REFERENCE(ch_simulation_inputs)

    emit:
    reads = BADREAD_SIMULATE_WHOLE_REFERENCE.out.reads
}
