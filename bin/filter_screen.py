import argparse
from Bio import SeqIO
import pandas as pd
import sys

def parse_args(args=None):
    Description = "Extract genomes identified as contained via mash screen."
    Epilog = "Example usage: python filter_screen.py -r reference_fasta -s screen_results.tsv -o output.fasta"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-r",
        "--reference_fasta",
        help="Path to FASTA file that was sketched with mash sketch, and searched for containment with mash screen.",
    )
    parser.add_argument(
        "-s",
        "--mash_screen_results",
        help="Path to the TSV file output by running mash screen.",
    )
    parser.add_argument(
        "-o",
        "--output_fasta",
        help="Output FASTA file containing extracted mash screen hits.",
    )
    return parser.parse_args(args)

def extract_screen_hits(reference_fasta, screen_results, output_fasta):

    screen_results_df = pd.read_csv(screen_results, 
                            sep="\t",
                            header=None,
                            index_col=False,
                            names=["identity", "shared-hashes", "median-multiplicity", "p-value", "query-id", "query-comment"])

    screen_hits_set = set(screen_results_df['query-id'])

    print("Parsing reference FASTA")
    iteration = 0
    seqs_to_keep = []
    for record in SeqIO.parse(reference_fasta, "fasta"):
        # print status
        iteration += 1
        if iteration % 10000 == 0:
            print(iteration)

        if record.id in screen_hits_set:
            # add sequences passing filter to list
            seqs_to_keep.append(record)

    print(str(len(seqs_to_keep)) + " screen hits identified")

    # save sequences to specified file
    SeqIO.write(seqs_to_keep, output_fasta, "fasta")

def main(args=None):
    args = parse_args(args)
    extract_screen_hits(args.reference_fasta, args.mash_screen_results, args.output_fasta)


if __name__ == "__main__":
    sys.exit(main())