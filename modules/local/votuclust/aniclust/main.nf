process BLAST_ANICLUST {
    tag "$parsed_combined_fasta"
    label 'process_low'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.2.4"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'quay.io/biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    path parsed_combined_fasta
    path ani_tsv

    output:
    path('*_clusters.tsv') , emit: clusters_tsv
    path  "versions.yml" , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    aniclust.py \\
    --fna $parsed_combined_fasta \\
    --ani $ani_tsv \\
    --out ${parsed_combined_fasta}_clusters.tsv \\
    $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version 2>&1 | sed 's/^.*Python v//; s/ .*\$//')
    END_VERSIONS
    """
}
