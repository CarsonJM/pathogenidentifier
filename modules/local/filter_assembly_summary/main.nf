process FILTER_ASSEMBLY_SUMMARY {
    tag "$meta.id"
    label 'process_high'

    conda "conda-forge::biopython=1.78 conda-forge::pandas=1.3.5"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' :
        'biocontainers/mulled-v2-80c23cbcd32e2891421c54d1899665046feb07ef:77a31e289d22068839533bf21f8c4248ad274b60-0' }"

    input:
    tuple val(meta), path(sourmash_hits)

    output:
    tuple val(meta), path("*_filtered_assembly_summary.txt")    , emit: filtered_assembly_summary
    path "versions.yml"                                        , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    filter_assembly_summary.py \\
    -g https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_genbank.txt \\
    -r https://ftp.ncbi.nlm.nih.gov/genomes/ASSEMBLY_REPORTS/assembly_summary_refseq.txt \\
    -s $sourmash_hits \\
    -o ${prefix}_filtered_assembly_summary.txt

    sed -i -e "1i ##  See ftp://ftp.ncbi.nlm.nih.gov/genomes/README_assembly_summary.txt for a description of the columns in this file." ${prefix}_filtered_assembly_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
    END_VERSIONS
    """


    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_filtered_assembly_summary.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pandas: \$(echo \$(pandas_version.py 2>&1))
    END_VERSIONS
    """
}
