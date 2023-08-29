//
// Dereplicate phage genomes across samples
//
include { CAT_CAT                           } from '../../modules/nf-core/cat/cat/main'
include { GUNZIP                            } from '../../modules/nf-core/gunzip/main'
include { BLAST_MAKEBLASTDB                 } from '../../modules/nf-core/blast/makeblastdb/main'
include { BLAST_BLASTN                      } from '../../modules/nf-core/blast/blastn/main'
include { VOTU_ANICALC                      } from '../../modules/local/votu_anicalc/main'
include { VOTU_ANICLUST                     } from '../../modules/local/votu_aniclust/main'
include { EXTRACT_VOTU_REPRESENTATIVES      } from '../../modules/local/extract_votu_representatives/main'

workflow PHAGE_DEREPLICATION {
    take:
    aligned_phage    // [ [ meta ], [ fasta ] ]

    main:
    ch_versions           = Channel.empty()

    //
    // MODULE: Comine aligned phage FASTA files across samples
    //
    ch_aligned_phage_all_samples = aligned_phage.map{ it -> it[1] }.collect()
        .map { aligned_phage ->
                def meta = [:]
                meta.id     = 'all_samples'
                return [ meta, aligned_phage ] }
    ch_combined_phage_fasta = CAT_CAT ( ch_aligned_phage_all_samples ).file_out

    //
    // MODULE: Make BLAST database for phage all-v-all alignment
    //
    BLAST_MAKEBLASTDB ( ch_combined_phage_fasta )

    //
    // MODULE: Run all-v-all BLAST
    //
    BLAST_BLASTN ( ch_combined_phage_fasta, BLAST_MAKEBLASTDB.out.db )

    //
    // MODULE: Calculate ANI from BLAST results
    //
    VOTU_ANICALC ( BLAST_BLASTN.out.txt )

    //
    // MODULE: Cluster phage genomes based on ANI and AF
    //
    VOTU_ANICLUST ( ch_combined_phage_fasta, VOTU_ANICALC.out.ani_tsv )

    //
    // MODULE: Extract cluster representatives
    //
    EXTRACT_VOTU_REPRESENTATIVES ( ch_combined_phage_fasta, VOTU_ANICLUST.out.clusters_tsv )

    emit:
    votu_representatives  = EXTRACT_VOTU_REPRESENTATIVES.out.votu_representatives  // channel: [ val(meta), [ fasta ] ]
    versions            = ch_versions                               // channel: [ versions.yml ]
}
