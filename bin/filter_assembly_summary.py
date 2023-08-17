#!/usr/bin/env python

import argparse
import pandas as pd
from Bio import SeqIO
import sys
import gzip

def parse_args(args=None):
    Description = "Filter NCBI GenBank and RefSeq assembly summaries based upon contained genome accessions"
    Epilog = "Example usage: python filter_assembly_summary.py -g assembly_summary_genbank.txt -r assembly_summary_refseq.txt -s sourmash_output.csv -o assembly_summary_filtered.txt"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-g",
        "--genbank_assembly_summary",
        help="Path to assembly_summary_genbank.txt",
    )
    parser.add_argument(
        "-r",
        "--refseq_assembly_summary",
        help="Path to assembly_summary_refseq.txt",
    )
    parser.add_argument(
        "-s",
        "--sourmash_results",
        help="Path to results file from sourmash gather.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output filtered assembly_summary.txt file.",
    )
    return parser.parse_args(args)

def filter_assembly_summary(genbank_summary, refseq_summary, sourmash_results, output):
    with gzip.open(sourmash_results, "rt") as sourmash_results_gunzip:
        sourmash_results_df = pd.read_csv(
            sourmash_results_gunzip
        )
    sourmash_results_df['accession'] = sourmash_results_df['name'].str.split(' ', expand=True)[0]
    sourmash_contained_accessions = set(sourmash_results_df['accession'])
    genbank_summary_df = pd.read_csv(genbank_summary, sep='\t', header=1, low_memory=False)
    refseq_summary_df = pd.read_csv(refseq_summary, sep='\t', header=1, low_memory=False)
    filtered_genbank_summary = genbank_summary_df[genbank_summary_df['#assembly_accession'].isin(sourmash_contained_accessions)]
    filtered_refseq_summary = refseq_summary_df[refseq_summary_df['#assembly_accession'].isin(sourmash_contained_accessions)]
    combined_filtered_summary = pd.concat([filtered_genbank_summary, filtered_refseq_summary], axis=0)
    combined_filtered_summary.to_csv(output, sep='\t', index=False)

def main(args=None):
    args = parse_args(args)
    filter_assembly_summary(args.genbank_assembly_summary, args.refseq_assembly_summary, args.sourmash_results, args.output)


if __name__ == "__main__":
    sys.exit(main())
