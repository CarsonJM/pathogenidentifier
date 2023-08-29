process COVERM_PHAGE_AND_BACTERIA {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::coverm=0.6.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/coverm:0.6.1--h1535e20_5':
        'biocontainers/coverm:0.6.1--h1535e20_5' }"

    input:
    tuple val(meta), path(dereplicated_bacteria)
    tuple val(meta), path(dereplicated_phage)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_final_alignment_results.tsv")  , emit: alignment_results
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p phage_and_bacteria_combined
    mv ${dereplicated_phage} phage_and_bacteria_combined
    mv ${dereplicated_bacteria} phage_and_bacteria_combined

    coverm \\
        genome \\
        -1 ${reads[0]} \\
        -2 ${reads[1]} \\
        --methods covered_bases \\
        --genome-fasta-directory phage_and_bacteria_combined \\
        --genome-fasta-extension fna \\
        --output-file ${prefix}_final_alignment_results.tsv \\
        --threads $task.cpus \\
        $args


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(echo \$(coverm --version 2>&1) | sed 's/^.*coverm //; s/Using.*\$//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_bacteria_alignment_results.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        coverm: \$(echo \$(coverm --version 2>&1) | sed 's/^.*coverm //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
