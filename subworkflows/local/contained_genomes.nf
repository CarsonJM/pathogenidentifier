//
// Identify contained genomes with sourmash
//
include { SOURMASH_SKETCH as SOURMASH_SKETCH_READS      } from '../../modules/nf-core/sourmash/sketch/main'
include { SOURMASH_SKETCH as SOURMASH_SKETCH_PHAGE      } from '../../modules/nf-core/sourmash/sketch/main'
include { SOURMASH_GATHER as SOURMASH_GATHER_BACTERIA   } from '../../modules/nf-core/sourmash/gather/main'
include { SOURMASH_GATHER as SOURMASH_GATHER_PHAGE      } from '../../modules/nf-core/sourmash/gather/main'
include { GENOME_UPDATER                                } from '../../modules/local/genome_updater'
include { EXTRACT_CONTAINED_PHAGE                       } from '../../modules/local/extract_contained_phage'

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
    ch_bacterial_genomes = GENOME_UPDATER ( ch_contained_bacteria )

    // Identify contained phages
    ch_phage_sketch = SOURMASH_SKETCH_PHAGE ( params.containment_phage_fasta ).signatures
    ch_contained_phage = SOURMASH_GATHER_PHAGE ( ch_reads_sketch, ch_phage_sketch, false, false, false, false ).result
    ch_phage_hits = EXTRACT_CONTAINED_PHAGE ( ch_contained_phage, params.containment_phage_fasta )

    emit:
    phage_genomes      = ch_phage_genomes       // channel: [ val(meta), [ fasta ] ]
    bacterial_genomes  = ch_bacterial_genomes   // channel: [ val(meta), [ fasta ] ]
    versions           = ch_versions            // channel: [ versions.yml ]
}
