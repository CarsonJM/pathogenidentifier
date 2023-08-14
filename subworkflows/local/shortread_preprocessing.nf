//
// Perform read trimming and merging
//


include { SHORTREAD_FASTP             } from './shortread_fastp'

workflow SHORTREAD_PREPROCESSING {
    take:
    reads //  [ [ meta ], [ reads ] ]
    adapterlist // file

    main:
    ch_versions       = Channel.empty()
    ch_multiqc_files  = Channel.empty()


    ch_processed_reads = SHORTREAD_FASTP ( reads, adapterlist ).reads
    ch_versions        =  ch_versions.mix( SHORTREAD_FASTP.out.versions )
    ch_multiqc_files   =  ch_multiqc_files.mix( SHORTREAD_FASTP.out.mqc )


    FASTQC_PROCESSED ( ch_processed_reads )
    ch_versions = ch_versions.mix( FASTQC_PROCESSED.out.versions )
    ch_multiqc_files = ch_multiqc_files.mix( FASTQC_PROCESSED.out.zip )


    emit:
    reads    = ch_processed_reads   // channel: [ val(meta), [ reads ] ]
    versions = ch_versions          // channel: [ versions.yml ]
    mqc      = ch_multiqc_files
}
