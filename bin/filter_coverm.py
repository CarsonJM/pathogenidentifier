from Bio import SeqIO
import pandas as pd
import argparse
import sys

def parse_args(args=None):
    Description = "Extract genomes covered via read alignment."
    Epilog = "Example usage: python filter_coverm.py -r reference_fasta -c coverm_results.tsv -o output.fasta"

    parser = argparse.ArgumentParser(description=Description, epilog=Epilog)
    parser.add_argument(
        "-r",
        "--reference_fasta",
        help="Path to FASTA file that was sketched with mash sketch, and searched for containment with mash screen.",
    )
    parser.add_argument(
        "-c",
        "--coverm_results",
        help="Path to the TSV file output by running mash coverM.",
    )
    parser.add_argument(
        "-o",
        "--output_fasta",
        help="Output FASTA file containing extracted coverM hits.",
    )
    return parser.parse_args(args)

def extract_coverm_hits(reference_fasta, coverm_results, output_fasta):

    coverm_results_df = pd.read_csv(coverm_results, 
                            sep="\t",
                            header=0,
                            names=["contig", "rpkm"])

    coverm_results_filt = coverm_results_df[coverm_results_df['rpkm'].astype(float) > 0]
    coverm_hits_set = set(coverm_results_filt['contig'])

    iteration = 0
    phages_to_keep = []
    print("Parsing reference FASTA")
    iteration = 0
    seqs_to_keep = []
    for record in SeqIO.parse(reference_fasta, "fasta"):
        # print status
        iteration += 1
        if iteration % 100 == 0:
            print(iteration)

        if record.id in coverm_hits_set:
            # add sequences passing filter to list
            seqs_to_keep.append(record)

    print(str(len(seqs_to_keep)) + " coverM hits identified")

    # save sequences to specified file
    SeqIO.write(seqs_to_keep, output_fasta, "fasta")


def main(args=None):
    args = parse_args(args)
    extract_coverm_hits(args.reference_fasta, args.coverm_results, args.output_fasta)


if __name__ == "__main__":
    sys.exit(main())