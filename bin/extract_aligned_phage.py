#!/usr/bin/env python

import argparse
import pandas as pd
from Bio import SeqIO
import sys
import gzip


def parse_args(args=None):
    Description = "Extract phage genomes with substantial read alignment, as determined using CoverM contig."
    Epilog = "Example usage: python extract_aligned_phage.py -p phage_fasta.fna.gz -s coverm_results.tsv -o phage_genomes.aligned.fna"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-p",
        "--phage_fasta",
        help="Path to FASTA file (gzipped) that was sketched with sourmash sketch, and searched for containment with sourmash gather.",
    )
    parser.add_argument(
        "-s",
        "--coverm_results",
        help="Path to the TSV file output by running CoverM contig.",
    )
    parser.add_argument(
        "-m",
        "--min_covered_bases",
        help="Minimum number of bases covered by reads to consider a phage present in a sample.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output FASTA file containing genomes with substantial alignment as determined via CoverM contig.",
    )
    return parser.parse_args(args)


def extract_contained_phage(phage_fasta, coverm_results, min_covered_bases, output):
    coverm_results_df = pd.read_csv(
        coverm_results,
        sep='\t',
        names=['contigs', 'covered_bases']
    )
    coverm_results_filtered = coverm_results_df[coverm_results_df['covered_bases'] > min_covered_bases]
    coverm_aligned_contigs = set(coverm_results_filtered['contigs'])

    aligned_genomes = []
    tested_genomes = set()
    for record in SeqIO.parse(phage_fasta, "fasta"):
        if record.id in coverm_aligned_contigs:
            if record.id in tested_genomes:
                continue
            else:
                aligned_genomes.append(record)
                tested_genomes.add(record.id)
    SeqIO.write(aligned_genomes, output, "fasta")


def main(args=None):
    args = parse_args(args)
    extract_contained_phage(args.phage_fasta,
                            args.coverm_results,
                            args.min_covered_bases,
                            args.output)


if __name__ == "__main__":
    sys.exit(main())
