//
// ALign reads to genomes contained the same sample
//
include { COVERM_CONTIG             } from '../../modules/local/coverm/contig/main'
include { COVERM_GENOME             } from '../../modules/local/coverm/genome/main'
include { EXTRACT_ALIGNED_PHAGE     } from '../../modules/local/extract_aligned_phage/main'
include { EXTRACT_ALIGNED_BACTERIA  } from '../../modules/local/extract_aligned_bacteria/main'

workflow SAMPLE_ALIGNMENT {
    take:
    reads               // [ [ meta ], [ fastq ] ]
    contained_bacteria  // [ [ meta ], [ fasta ] ]
    contained_phage     // [ [ meta ], [ fasta ] ]

    main:
    ch_versions           = Channel.empty()

    //
    // MODULE: Align reads to contained phage contigs
    //
    ch_phage_alignments = COVERM_CONTIG ( contained_phage, reads ).alignment_results

    //
    // MODULE: Align reads to contained bacterial genomes
    //
    ch_bacteria_alignments = COVERM_GENOME ( contained_bacteria, reads ).alignment_results

    //
    // MODULE: Extract phage genomes with substantial read alignment
    //
    ch_aligned_phage = EXTRACT_ALIGNED_PHAGE ( contained_phage, ch_phage_alignments ).aligned_phage

    //
    // MODULE: Extract bacterial genomes with substantial read alignment
    //
    ch_aligned_bacteria = EXTRACT_ALIGNED_BACTERIA ( contained_bacteria, ch_bacteria_alignments ).aligned_bacteria

    emit:
    aligned_phage       = ch_aligned_phage      // channel: [ val(meta), [ fasta ] ]
    aligned_bacteria    = ch_aligned_bacteria   // channel: [ val(meta), [ fasta ] ]
    versions            = ch_versions           // channel: [ versions.yml ]
}
