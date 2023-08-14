//
// Predict phage hosts with iPHop
//
include { IPHOP_DOWNLOAD    } from '../../modules/nf-core/iphop/download/main'
include { IPHOP_PREDICT     } from '../../modules/nf-core/iphop/predict/main'
include { SOURMASH_GATHER as GATHER_BACTERIA    } from '../../modules/nf-core/sourmash/gather/main'

workflow CONTAINED_GENOMES {
    take:
    reads // [[meta], [reads]]

    main:
    ch_versions           = Channel.empty()

    ch_reads_sketch = SOURMASH_SKETCH ( reads ).signatures

    // Bacteria
    ch_bacterial_sketch = file('https://farm.cse.ucdavis.edu/~ctbrown/sourmash-db/gtdb-rs214/gtdb-rs214-reps.k21.zip', checkIfExists: true)
    ch_contained_bacteria = GATHER_BACTERIA ( ch_reads_sketch, ch_bacterial_sketch, false, false, false, false ).result
    ch_bacterial_hits = GENOME_UPDATER ( ch_contained_bacteria, 'bacteria' )

    // Phage
    if ( params.containment_phage_sketch ){
        ch_phage_sketch = file(params.containment_phage_sketch, checkIfExists: true)
    } else {
        ch_phage_sketch = SKETCH_PHAGE ( params.containment_phage_fasta ).signatures
        ch_versions = ch_versions.mix( SKETCH_PHAGE.out.versions )
    }

    ch_contained_phage = GATHER_PHAGE ( ch_reads_sketch, ch_phage_sketch, false, false, false, false ).result
    ch_phage_hits = EXTRACT_CONTAINED_PHAGE ( ch_contained_phage, params.containment_phage_fasta )

    emit:
    phage_hits      = ch_phage_hits     // channel: [ val(meta), [ fasta ] ]
    bacterial_hits  = ch_bacterial_hits // channel: [ val(meta), [ fasta ] ]
    versions = ch_versions          // channel: [ versions.yml ]
}
