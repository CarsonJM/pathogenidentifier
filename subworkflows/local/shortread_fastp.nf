//
// Process short raw reads with FastP
//

include { FASTP as FASTP_PAIRED       } from '../../modules/nf-core/fastp/main'

workflow SHORTREAD_FASTP {
    take:
    reads // [[meta], [reads]]
    adapterlist

    main:
    ch_versions           = Channel.empty()
    ch_multiqc_files      = Channel.empty()

    // Last parameter here turns on merging of PE data
    FASTP_PAIRED ( reads, adapterlist, false, params.shortread_qc_mergepairs )

    if ( params.shortread_qc_mergepairs ) {
        ch_fastp_reads_prepped_pe = FASTP_PAIRED.out.reads_merged
                                        .map {
                                            meta, reads ->
                                                def meta_new = meta.clone()
                                                meta_new['single_end'] = true
                                                [ meta_new, [ reads ].flatten() ]
                                        }

        ch_fastp_reads_prepped = ch_fastp_reads_prepped_pe.mix( FASTP_SINGLE.out.reads )

    } else {
        ch_fastp_reads_prepped = FASTP_PAIRED.out.reads
    }

    ch_versions = ch_versions.mix(FASTP_PAIRED.out.versions.first())
    ch_processed_reads = ch_fastp_reads_prepped
    ch_multiqc_files = ch_multiqc_files.mix( FASTP_PAIRED.out.json )

    emit:
    reads    = ch_processed_reads   // channel: [ val(meta), [ reads ] ]
    versions = ch_versions          // channel: [ versions.yml ]
    mqc      = ch_multiqc_files
}
