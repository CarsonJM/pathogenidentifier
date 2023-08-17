process DREP_DEREPLICATE {
    label 'process_high'

    conda "bioconda::drep=3.4.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/drep:3.4.3--pyhdfd78af_0':
        'biocontainers/drep:3.4.3--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bacteria_genomes)

    output:
    path("dereplicated_genomes/*.fna.gz") , emit: dereplicated_bacteria
    path "versions.yml"                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    gunzip ./*.fna.gz

    dRep \\
        dereplicate \\
            . \\
            --processors $task.cpus \\
            --genomes ./*.fna \\
            --ignoreGenomeQuality \\
            $args

    gzip dereplicated_genomes/*.fna


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$(echo \$(dRep --version 2>&1) | sed 's/^.*dRep //; s/Using.*\$//' ))
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p dereplicated_genomes
    touch dereplicated_genomes/genome.fna.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        drep: \$(echo \$(dRep --version 2>&1) | sed 's/^.*dRep //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
