#!/usr/bin/env python

import argparse
import pandas as pd
from Bio import SeqIO
import sys
import gzip


def parse_args(args=None):
    Description = "Extract phage genomes contained in reads, as determined using sourmash gather."
    Epilog = "Example usage: python extract_phage_genomes.py -p phage_fasta.fna.gz -s sourmash_results.csv -o phage_genomes.fna"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-p",
        "--phage_fasta",
        help="Path to FASTA file (gzipped) that was sketched with sourmash sketch, and searched for containment with sourmash gather.",
    )
    parser.add_argument(
        "-s",
        "--sourmash_results",
        help="Path to the CSV file output by running sourmash gather.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Output FASTA file containing genomes identified as contained by sourmash gather.",
    )
    return parser.parse_args(args)


def extract_contained_phage(phage_fasta, sourmash_results, output):
    with gzip.open(sourmash_results, "rt") as sourmash_results_gunzip:
        sourmash_results_df = pd.read_csv(
            sourmash_results_gunzip
        )
    sourmash_results_df['accession'] = sourmash_results_df['name'].str.split(' ', expand=True)[0]
    sourmash_contained_accessions = set(sourmash_results_df['accession'])

    contained_genomes = []
    tested_genomes = set()
    with gzip.open(phage_fasta, "rt") as phage_fasta_gunzip:
        for record in SeqIO.parse(phage_fasta_gunzip, "fasta"):
            if record.id in sourmash_contained_accessions:
                if record.id in tested_genomes:
                    continue
                else:
                    record.id = "mash_screen|" + record.id
                    contained_genomes.append(record)
                    tested_genomes.add(record.id)
    SeqIO.write(contained_genomes, output, "fasta")


def main(args=None):
    args = parse_args(args)
    extract_contained_phage(args.phage_fasta,
                            args.sourmash_results,
                            args.output)


if __name__ == "__main__":
    sys.exit(main())
