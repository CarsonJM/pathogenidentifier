process EXTRACT_ALIGNED_PHAGE {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.3.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    tuple val(meta), path(contained_phage), path(phage_alignments)

    output:
    tuple val(meta), path("*.aligned.fna")   , emit: aligned_phage
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    extract_aligned_phage.py \\
    -p $contained_phage \\
    -s $phage_alignments \\
    -m $params.alignment_min_covered_bases_phage \\
    -o ${prefix}.aligned.fna

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
    touch ${prefix}.aligned.fna.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
        biopython: \$(echo \$(biopython_version.py 2>&1))
    END_VERSIONS
    """
}
