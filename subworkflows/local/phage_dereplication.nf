//
// Dereplicate phage genomes across samples
//
include { CAT_CAT                           } from '../../modules/nf-core/cat/cat/main'
include { BLAST_MAKEBLASTDB                 } from '../../modules/nf-core/blast/makeblastdb/main'
include { BLAST_BLASTN                      } from '../../modules/nf-core/blast/blastn/main'
include { ANICALC                           } from '../../modules/local/votuclust/anicalc/main'
include { ANICLUST                          } from '../../modules/local/votuclust/aniclust/main'
include { EXTRACT                           } from '../../modules/local/votuclust/extract/main'

workflow PHAGE_DEREPLICATION {
    take:
    aligned_phage    // [ [ meta ], [ fasta ] ]

    main:
    ch_versions           = Channel.empty()

    //
    // MODULE: Comine aligned phage FASTA files across samples
    //
    ch_aligned_phage_all_samples = Channel.of(aligned_phage.map{ [ [ id:'combined_aligned_phages' ], it[1] ] }.groupTuple())
    ch_combined_phage_fasta = CAT_CAT ( ch_aligned_phage_all_samples ).file_out

    //
    // MODULE: Make BLAST database for phage all-v-all alignment
    //
    BLAST_MAKEBLASTDB ( ch_combined_phage_fasta )

    //
    // MODULE: Run all-v-all BLAST
    //
    BLAST_BLASTN ( BLAST_MAKEBLASTDB.out.db )

    //
    // MODULE: Calculate ANI from BLAST results
    //
    VOTUCLUST_ANICALC ( BLAST_BLASTN.out.txt )

    //
    // MODULE: Cluster phage genomes based on ANI and AF
    //
    VOTUCLUST_ANICLUST ( ch_combined_phage_fasta, VOTUCLUST_ANICALC.out.ani_tsv )

    //
    // MODULE: Extract cluster representatives
    //
    VOTUCLUST_EXTRACT ( ch_combined_phage_fasta, VOTUCLUST_ANICLUST.out.clusters_tsv )

    emit:
    dereplicated_phage  = VOTUCLUST_EXTRACT.out.dereplicated_phage  // channel: [ val(meta), [ fasta ] ]
    versions            = ch_versions                               // channel: [ versions.yml ]
}
