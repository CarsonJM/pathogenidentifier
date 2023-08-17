process EXTRACT_CONTAINED_PHAGE {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.3.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    tuple val(meta), path(sourmash_hits)
    path (phage_fasta)

    output:
    tuple val(meta), path("*.phage_genomes.fna.gz") , emit: phage_genomes
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    extract_contained_phage.py \\
    -p $phage_fasta \\
    -s $sourmash_hits \\
    -o ${prefix}.phage_genomes.fna

    gzip ${prefix}.phage_genomes.fna

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.phage_genomes.fna.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
    END_VERSIONS
    """
}
