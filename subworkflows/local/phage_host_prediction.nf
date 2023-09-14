//
// Predict phage hosts with iPHop
//
include { IPHOP_DOWNLOAD    } from '../../modules/nf-core/iphop/download/main'
include { IPHOP_PREDICT     } from '../../modules/nf-core/iphop/predict/main'
include { CAT_CAT2          } from '../../modules/nf-core/cat/cat2/main'

workflow PHAGE_HOST_PREDICTION {
    take:
    dereplicated_phage // [[meta], [reads]]

    main:
    ch_versions           = Channel.empty()

    //
    // MODULE: Download iphop database
    //
    if ( params.iphop_db ){
        ch_iphop_db = file(params.iphop_db, checkIfExists: true)
    } else {
        ch_iphop_db = IPHOP_DOWNLOAD ( ).iphop_db
        ch_versions = ch_versions.mix( IPHOP_DOWNLOAD.out.versions )
    }

    //
    // MODULE: Combine virus fastas into one
    //
    ch_combined_virus_fasta = CAT_CAT2 ( dereplicated_phage ).file_out

    //
    // MODULE: Predict virus host using iPHoP
    //
    ch_split_seqs_fasta = ch_combined_virus_fasta.splitFasta( by: 100, file: true)
    IPHOP_PREDICT ( ch_split_seqs_fasta, ch_iphop_db )
    ch_versions = ch_versions.mix( IPHOP_PREDICT.out.versions )

    emit:
    phage_hosts      = IPHOP_PREDICT.out.iphop_genus     // channel: [ val(meta), [ fasta ] ]
    versions = ch_versions          // channel: [ versions.yml ]
}
