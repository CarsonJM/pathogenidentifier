//
// Dereplicate bacterial genomes across samples
//
include { GUNZIP } from '../../modules/nf-core/gunzip/main'
include { DREP_DEREPLICATE } from '../../modules/local/drep/dereplicate/main'

workflow BACTERIA_DEREPLICATION {
    take:
    aligned_bacteria    // [ [ meta ], [ fasta ] ]

    main:
    ch_versions           = Channel.empty()

    //
    // MODULE: Dereplicate bacterial genomes across samples
    //
    ch_aligned_bacteria_all_samples = aligned_bacteria.map{ it -> it[1] }.collect()
        .map { aligned_bacteria ->
                def meta = [:]
                meta.id     = 'all_samples'
                return [ meta, aligned_bacteria ] }

    DREP_DEREPLICATE ( ch_aligned_bacteria_all_samples )

    emit:
    dereplicated_bacteria  = DREP_DEREPLICATE.out.dereplicated_bacteria // channel: [ val(meta), [ fasta ] ]
    versions               = ch_versions                                // channel: [ versions.yml ]
}
