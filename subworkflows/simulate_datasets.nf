#!/usr/bin/env nextflow
import java.nio.file.Paths


process downsample_dataset {

    container 'quay.io/biocontainers/rasusa:2.1.0--h715e4b3_0'

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq)
    val(dataset_coverage)

    output:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path("${dataset_accession}.subsampled.fastq.gz")

    script:
    """
    rasusa reads --bases ${dataset_coverage} ${dataset_fastq} -o "${dataset_accession}.subsampled.fastq.gz"
    """
}

process downsample_dataset_paired {

    container 'quay.io/biocontainers/rasusa:2.1.0--h715e4b3_0'

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq1), path(dataset_fastq2)
    val(dataset_coverage)

    output:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path("${dataset_accession}_1.subsampled.fastq.gz"), path("${dataset_accession}_2.subsampled.fastq.gz")

    script:
    """
    rasusa reads --bases ${dataset_coverage} ${dataset_fastq1} ${dataset_fastq2} -o "${dataset_accession}_1.subsampled.fastq.gz" -o "${dataset_accession}_2.subsampled.fastq.gz"
    """
}

process simulate_reads {

    container 'quay.io/biocontainers/badread:0.4.1--pyhdfd78af_0'

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq)

    output:
    tuple val(index), val(ref_accession), val(ref_category), path("${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads.fq.gz"), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq)

    script:
    simulator = params.lookup["${platform}"]
    if ("${simulator}" == "badread") {
        """
        badread simulate --reference ${ref_fasta} --quantity ${ref_coverage}x ${params.badread_args} > ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads.fq
        gzip ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads.fq
        """
    } else {
        error "Unsupported simulator: ${simulator} for platform ${platform}"
    }
}

process simulate_reads_paired {

    container 'community.wave.seqera.io/library/wgsim_bc:7ed358cfbb01b031'

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fasta), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq1), path(dataset_fastq2)
    output:
    tuple val(index), val(ref_accession), val(ref_category), path("${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_1.fq.gz"), path("${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_2.fq.gz"), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq1), path(dataset_fastq2)

    script:
    simulator = params.lookup["${platform}"]
    if ("${simulator}" == "wgsim") {
        read_type = "illumina"
        """
        genome_length=\$(cat ${ref_fasta} | wc -c)
        num_reads=\$(echo "\$genome_length*${ref_coverage}/300" | bc)
        echo "\$genome_length \$num_reads"
        wgsim -N \$num_reads ${params.wgsim_args} ${ref_fasta} ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_1.fq ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_2.fq
        gzip ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_1.fq ${ref_accession}_${index}_${simulator}_${ref_coverage}x_reads_2.fq
        """
    } else {
        error "Unsupported simulator: ${simulator} for platform ${platform}"
    }
}

process combine_for_recipe {

    container 'community.wave.seqera.io/library/wgsim_bc:7ed358cfbb01b031'


    publishDir "${params.output_dir}/${ref_category}", mode: "copy"

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fastq), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq)

    output:
    tuple val(index), val(ref_accession), val(ref_category), val(ref_coverage), val(dataset_accession), val(platform), path("${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}.fq.gz")

    script:
    simulator = params.lookup["${platform}"]
    """
    cat ${ref_fastq} ${dataset_fastq} > ${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}.fq.gz
    """
}

process combine_for_recipe_paired {

    container 'community.wave.seqera.io/library/wgsim_bc:7ed358cfbb01b031'


    publishDir "${params.output_dir}/${ref_category}", mode: "copy"

    input:
    tuple val(index), val(ref_accession), val(ref_category), path(ref_fastq1), path(ref_fastq2), val(ref_coverage), val(dataset_accession), val(platform), path(dataset_fastq1), path(dataset_fastq2)

    output:
    tuple val(index), val(ref_accession), val(ref_category), val(ref_coverage), val(dataset_accession), val(platform), path("${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}_R1.fq.gz"), path("${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}_R2.fq.gz")

    script:
    simulator = params.lookup["${platform}"]
    """
    cat ${ref_fastq1} ${dataset_fastq1} > ${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}_R1.fq.gz
    cat ${ref_fastq2} ${dataset_fastq2} > ${dataset_accession}_${ref_accession}_${simulator}_${ref_coverage}x_${index}_R2.fq.gz
    """
}

workflow generate_unpaired {
    take:
        recipes
    main:
        downsample_dataset(recipes, params.dataset_coverage)
        simulate_reads(downsample_dataset.out)
        combine_for_recipe(simulate_reads.out)
    emit:
        combine_for_recipe.out
}

workflow generate_paired {
    take:
        recipes
    main:
        downsample_dataset_paired(recipes, params.dataset_coverage)
        simulate_reads_paired(downsample_dataset_paired.out)
        combine_for_recipe_paired(simulate_reads_paired.out)
    emit:
        combine_for_recipe_paired.out
}

workflow simulate_datasets {
    take:
        paired_recipes
        unpaired_recipes
    main:
        generate_unpaired(unpaired_recipes)
        generate_paired(paired_recipes)
        generate_unpaired.out.view()
        generate_paired.out.view()
}
