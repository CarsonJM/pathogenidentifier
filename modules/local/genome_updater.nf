process GENOME_UPDATER {
    tag "$meta.id"
    label 'process_high'

    conda "bioconda::genome_updater=0.6.3"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genome_updater:0.6.3--hdfd78af_1':
        'biocontainers/genome_updater:0.6.3--hdfd78af_1' }"

    input:
    tuple val(meta), path(sourmash_hits)

    output:
    tuple val(meta), path("contained_bacterial_genomes"), emit: contained_bacterial_genomes
    path "versions.yml"                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    cat

    genome_updater.sh \\
        -d "refseq,genbank" \\
        -g "bacteria" \\
        -f "genomic.fna.gz" \\
        -o contained_bacterial_genomes \\
        -t $task.cpus \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.bam

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        : \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
