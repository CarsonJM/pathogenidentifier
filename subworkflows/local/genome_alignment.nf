//
// Identify genomes with read alignments
//
include { COVERM_CONTIG             } from '../../modules/local/coverm_contig'
include { EXTRACT_ALIGNED_GENOMES   } from '../../modules/local/extract_aligned_genomes'

workflow CONTAINED_GENOMES {
    take:
    reads // [[meta], [reads]]

    main:
    ch_versions           = Channel.empty()

    // Make sketch of reads
    ch_reads_sketch = SOURMASH_SKETCH_READS ( reads ).signatures

    // Identify contained bacteria
    ch_bacteria_sketch = file('https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-k21.zip', checkIfExists: true)
    ch_contained_bacteria = SOURMASH_GATHER_BACTERIA ( ch_reads_sketch, ch_bacteria_sketch, false, false, false, false ).result
    // Download bacterial hits
    ch_bacterial_genomes = GENOME_UPDATER ( ch_contained_bacteria, 'bacteria' )

    // Identify contained phages
    ch_phage_sketch = SOURMASH_SKETCH_PHAGE ( params.containment_phage_fasta ).signatures
    ch_contained_phage = SOURMASH_GATHER_PHAGE ( ch_reads_sketch, ch_phage_sketch, false, false, false, false ).result
    ch_phage_hits = EXTRACT_CONTAINED_PHAGE ( ch_contained_phage, params.containment_phage_fasta )

    emit:
    phage_genomes      = ch_phage_genomes       // channel: [ val(meta), [ fasta ] ]
    bacterial_genomes  = ch_bacterial_genomes   // channel: [ val(meta), [ fasta ] ]
    versions           = ch_versions            // channel: [ versions.yml ]
}
