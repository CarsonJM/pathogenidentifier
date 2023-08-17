//
// Identify contained genomes with sourmash
//
include { SOURMASH_SKETCH as SOURMASH_SKETCH_READS      } from '../../modules/nf-core/sourmash/sketch/main'
include { SOURMASH_SKETCH as SOURMASH_SKETCH_PHAGE      } from '../../modules/nf-core/sourmash/sketch/main'
include { SOURMASH_GATHER as SOURMASH_GATHER_BACTERIA   } from '../../modules/nf-core/sourmash/gather/main'
include { SOURMASH_GATHER as SOURMASH_GATHER_PHAGE      } from '../../modules/nf-core/sourmash/gather/main'
include { FILTER_ASSEMBLY_SUMMARY                       } from '../../modules/local/filter_assembly_summary/main'
include { GENOME_UPDATER                                } from '../../modules/local/genome_updater/main'
include { EXTRACT_CONTAINED_PHAGE                       } from '../../modules/local/extract_contained_phage'

workflow CONTAINED_GENOMES {
    take:
    reads // [[meta], [reads]]

    main:
    ch_versions           = Channel.empty()

    // Make sketch of reads
    ch_reads_sketch = SOURMASH_SKETCH_READS ( reads, true ).signatures

    // Identify contained bacteria
    ch_bacteria_sketch = file('https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-reps.k21.zip', checkIfExists: true)
    ch_contained_bacteria = SOURMASH_GATHER_BACTERIA ( ch_reads_sketch, ch_bacteria_sketch, false, false, false, false ).result
    // Download bacterial hits
    ch_filtered_assembly_summary = FILTER_ASSEMBLY_SUMMARY ( ch_contained_bacteria ).filtered_assembly_summary
    ch_bacterial_genomes = GENOME_UPDATER ( ch_filtered_assembly_summary ).bacterial_genomes

    // Identify contained phages
    ch_phage_fasta = [ [ id:'reference' ], [ file(params.containment_phage_fasta, checkIfExists: true) ] ]
    ch_phage_sketch = SOURMASH_SKETCH_PHAGE ( ch_phage_fasta, false ).signatures
    ch_phage_sketch_no_meta = ch_phage_sketch.map{ it -> it[1] }
    ch_contained_phage = SOURMASH_GATHER_PHAGE ( ch_reads_sketch, ch_phage_sketch_no_meta, false, false, false, false ).result
    ch_phage_genomes = EXTRACT_CONTAINED_PHAGE ( ch_contained_phage, params.containment_phage_fasta ).phage_genomes

    emit:
    phage_genomes      = ch_phage_genomes       // channel: [ val(meta), [ fasta ] ]
    bacterial_genomes  = ch_bacterial_genomes   // channel: [ val(meta), [ fasta ] ]
    versions           = ch_versions            // channel: [ versions.yml ]
}
