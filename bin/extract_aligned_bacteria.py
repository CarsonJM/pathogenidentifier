#!/usr/bin/env python

import argparse
import pandas as pd
from Bio import SeqIO
import sys
import gzip
import os
import shutil


def parse_args(args=None):
    Description = "Extract bacterial genomes with substantial read alignment, as determined using CoverM genome."
    Epilog = "Example usage: python extract_aligned_bacteria.py -p bacterial_genomes -s coverm_results.tsv -m min_covered_bases -o aligned_bacterial_genomes"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-p",
        "--bacteria_fasta_dir",
        help="Path to directory containing FASTA files (gzipped) for bacteria contained in sample",
    )
    parser.add_argument(
        "-s",
        "--coverm_results",
        help="Path to the TSV file output by running CoverM genome.",
    )
    parser.add_argument(
        "-m",
        "--min_covered_bases",
        help="Minimum number of bases covered by reads to consider a bacteria present in a sample.",
    )
    parser.add_argument(
        "-r",
        "--prefix",
        help="Prefix for renaming FASTA files, so each filename is unique.",
    )
    parser.add_argument(
        "-o",
        "--output_dir",
        help="Output directory containing FASTA files for bacterial genomes with substantial alignment as determined via CoverM genome.",
    )
    return parser.parse_args(args)


def extract_contained_bacteria(bacteria_fasta_dir, coverm_results, min_covered_bases, prefix, output_dir):
    coverm_results_df = pd.read_csv(
        coverm_results,
        sep='\t',
        names=['genomes', 'covered_bases']
    )
    coverm_results_filtered = coverm_results_df[coverm_results_df['covered_bases'] > min_covered_bases]
    coverm_results_filtered['filename'] = coverm_results_filtered['genomes'] + '.fna'
    coverm_aligned_files = set(coverm_results_filtered['filename'])

    for file in os.listdir(bacteria_fasta_dir):
        filename = os.fsdecode(file)
        if filename in coverm_aligned_files:
            print(filename)
            print(file)
            shutil.copy2(bacteria_fasta_dir + '/' + file, output_dir + '/' + prefix + '_' + file)

def main(args=None):
    args = parse_args(args)
    extract_contained_bacteria(args.bacteria_fasta_dir,
                            args.coverm_results,
                            args.min_covered_bases,
                            args.prefix,
                            args.output_dir)


if __name__ == "__main__":
    sys.exit(main())
