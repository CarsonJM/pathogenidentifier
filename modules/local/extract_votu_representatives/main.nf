process EXTRACT_VOTU_REPRESENTATIVES {
    tag "$meta.id"
    label 'process_medium'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.2.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'quay.io/biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    tuple val(meta), path(fasta)
    tuple val(meta), path(clusters_tsv)

    output:
    tuple val(meta), path('*_votu_representatives/*.fna.gz') , emit: votu_representatives
    path  "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}_votu_representatives

    extract_votu_representatives.py \\
    $clusters_tsv \\
    $fasta \\
    ${prefix}_votu_representatives

    gzip ${prefix}_votu_representatives/*.fna

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/^.*Python v//; s/ .*\$//')
    END_VERSIONS
    """
}
