process GENOME_UPDATER {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::genome_updater=0.6.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genome_updater:0.6.3--hdfd78af_1':
        'biocontainers/genome_updater:0.6.3--hdfd78af_1' }"

    input:
    tuple val(meta), path(filtered_assembly_summary)

    output:
    tuple val(meta), path("*_bacterial_genomes")  , emit: bacterial_genomes
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    genome_updater.sh \\
        -e $filtered_assembly_summary \\
        -f "genomic.fna.gz" \\
        -M "gtdb" \\
        -o . \\
        -t $task.cpus \\
        -L curl \\
        -a \\
        $args

    mkdir -p ${prefix}_bacterial_genomes
    mv **/files/*.fna.gz ${prefix}_bacterial_genomes
    gunzip ${prefix}_bacterial_genomes/*.fna.gz


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genome_updater: 0.6.3
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p bacterial_genomes
    touch bacterial_genomes/bacterial_genome.fna.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        genome_updater: 0.6.3
    END_VERSIONS
    """
}
