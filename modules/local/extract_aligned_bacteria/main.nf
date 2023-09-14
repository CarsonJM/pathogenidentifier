process EXTRACT_ALIGNED_BACTERIA {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.3.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    tuple val(meta), path(contained_bacteria), path(bacteria_alignments)

    output:
    tuple val(meta), path("*.fna")    , emit: aligned_bacteria
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_aligned_bacteria_genomes
    extract_aligned_bacteria.py \\
    -p $contained_bacteria \\
    -s $bacteria_alignments \\
    -m $params.alignment_min_covered_bases_bacteria \\
    -r ${prefix} \\
    -o .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
        biopython: \$(echo \$(biopython_version.py 2>&1))
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ${prefix}_aligned_bacteria_genomes
    touch ${prefix}_aligned_bacteria_genomes/genome.fna.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
        biopython: \$(echo \$(biopython_version.py 2>&1))
    END_VERSIONS
    """
}
