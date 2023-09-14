/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap; fromSamplesheet } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowPathogenidentifier.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Local modules
//
include { COVERM_PHAGE_AND_BACTERIA } from '../modules/local/coverm/phage_and_bacteria/main'

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { SHORTREAD_PREPROCESSING   } from '../subworkflows/local/shortread_preprocessing'
include { SHORTREAD_HOSTREMOVAL     } from '../subworkflows/local/shortread_hostremoval'
include { CONTAINED_GENOMES         } from '../subworkflows/local/contained_genomes'
include { SAMPLE_ALIGNMENT          } from '../subworkflows/local/sample_alignment'
include { BACTERIA_DEREPLICATION    } from '../subworkflows/local/bacteria_dereplication'
include { PHAGE_DEREPLICATION       } from '../subworkflows/local/phage_dereplication'
include { PHAGE_HOST_PREDICTION     } from '../subworkflows/local/phage_host_prediction'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { FASTQC                      } from '../modules/nf-core/fastqc/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'
include { CAT_FASTQ                   } from '../modules/nf-core/cat/fastq/main'
include { GUNZIP as GUNZIP_PHAGE      } from '../modules/nf-core/gunzip/main'
include { GUNZIP as GUNZIP_BACTERIA   } from '../modules/nf-core/gunzip/main'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow PATHOGENIDENTIFIER {

    ch_versions = Channel.empty()

    // Read samplesheet using nf-validate
    Channel
        .fromSamplesheet("input")
        .multiMap { meta, fastq_1, fastq_2 ->
            fastq: [ meta, [ fastq_1, fastq_2 ] ]
        }
        .set { ch_input }

    /*
        MODULE: Run FastQC
    */
    FASTQC ( ch_input.fastq )
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())

    /*
        SUBWORKFLOW: PERFORM PREPROCESSING
    */
    adapterlist = params.shortread_qc_adapterlist ? file(params.shortread_qc_adapterlist) : []
    if ( params.perform_shortread_qc ) {
        ch_shortreads_preprocessed = SHORTREAD_PREPROCESSING ( ch_input.fastq, adapterlist ).reads
        ch_versions = ch_versions.mix( SHORTREAD_PREPROCESSING.out.versions )
    } else {
        ch_shortreads_preprocessed = ch_input.fastq
    }

    /*
        SUBWORKFLOW: HOST REMOVAL
    */
    if (params.perform_shortread_hostremoval && !params.hostremoval_reference) { exit 1, "ERROR: [nf-core/taxprofiler] --shortread_hostremoval requested but no --hostremoval_reference FASTA supplied. Check input." }
    if (!params.hostremoval_reference && params.shortread_hostremoval_index) { exit 1, "ERROR: [nf-core/taxprofiler] --shortread_hostremoval_index provided but no --hostremoval_reference FASTA supplied. Check input." }

    if (params.hostremoval_reference           ) { ch_reference = file(params.hostremoval_reference) }
    if (params.shortread_hostremoval_index     ) { ch_shortread_reference_index = Channel.fromPath(params.shortread_hostremoval_index).map{[[], it]} } else { ch_shortread_reference_index = [] }


    if ( params.perform_shortread_hostremoval ) {
        ch_shortreads_hostremoved = SHORTREAD_HOSTREMOVAL ( ch_shortreads_preprocessed, ch_reference, ch_shortread_reference_index ).reads
        ch_versions = ch_versions.mix(SHORTREAD_HOSTREMOVAL.out.versions)
    } else {
        ch_shortreads_hostremoved = ch_shortreads_preprocessed
    }

    /*
        RUN MERGING
    */
    if ( params.perform_runmerging ) {

        ch_reads_for_cat_branch = ch_shortreads_hostremoved
            .groupTuple()
            .map {
                meta, reads ->
                    [ meta, reads.flatten() ]
            }
            .branch {
                meta, reads ->
                // we can't concatenate files if there is not a second run, we branch
                // here to separate them out, and mix back in after for efficiency
                cat: ( reads.size() > 2 )
                skip: true
            }

        ch_reads_runmerged = CAT_FASTQ ( ch_reads_for_cat_branch.cat ).reads
            .mix( ch_reads_for_cat_branch.skip )
            .map {
                meta, reads ->
                [ meta, [ reads ].flatten() ]
            }
        ch_versions = ch_versions.mix(CAT_FASTQ.out.versions)

    } else {
        ch_reads_runmerged = ch_shortreads_hostremoved
    }

    /*
        SUBWORKFLOW: IDENTIFY CONTAINED GENOMES WITH SOURMASH
    */
    CONTAINED_GENOMES ( ch_reads_runmerged )
    ch_contained_bacteria = CONTAINED_GENOMES.out.bacterial_genomes
    ch_contained_phage = CONTAINED_GENOMES.out.phage_genomes

    /*
        SUBWORKFLOW: ALIGN READS TO CONTAINED GENOMES
    */
    SAMPLE_ALIGNMENT ( ch_reads_runmerged, ch_contained_bacteria, ch_contained_phage )
    ch_aligned_bacteria = SAMPLE_ALIGNMENT.out.aligned_bacteria
    ch_aligned_phage = SAMPLE_ALIGNMENT.out.aligned_phage

    /*
        SUBWORKFLOW: DEREPLICATE BACTERIAL GENOMES ACROSS SAMPLES
    */
    BACTERIA_DEREPLICATION ( ch_aligned_bacteria )
    ch_dereplicated_bacteria = BACTERIA_DEREPLICATION.out.dereplicated_bacteria

    /*
        SUBWORKFLOW: DEREPLICATE PHAGE GENOMES ACROSS SAMPLES
    */
    PHAGE_DEREPLICATION ( ch_aligned_phage )
    ch_dereplicated_phage = PHAGE_DEREPLICATION.out.votu_representatives

    /*
        SUBWORKFLOW: PREDICT HOST GENUS FOR PHAGES
    */
    PHAGE_HOST_PREDICTION ( ch_dereplicated_phage )


    //
    // MODULE: ALIGN READS TO DEREPLICATED DATABASE
    //
    COVERM_PHAGE_AND_BACTERIA ( ch_dereplicated_bacteria, ch_dereplicated_phage, ch_reads_runmerged )


    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

     //
     // MODULE: MultiQC
     //
    workflow_summary    = WorkflowPathogenidentifier.paramsSummaryMultiqc(workflow, summary_params)
    ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowPathogenidentifier.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
    ch_methods_description = Channel.value(methods_description)

    ch_multiqc_files = Channel.empty()
    ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList()
    )
    multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
