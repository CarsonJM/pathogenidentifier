#!/usr/bin/env python

import pandas as pd
from Bio import SeqIO
from sys import argv
import gzip

# get inputs
clusters_file = argv[1]
input_fasta = argv[2]
output_dir = argv[3]

# open clustering results
clusters = open(clusters_file, 'r')

derep_reps= []
for line in clusters:
    stripped = line.strip()
    centroid, nodes = stripped.split('\t')
    derep_base = centroid
    if len(derep_base.split('|provirus')) > 1:
        derep_base = derep_base.split('|provirus')[0]
    if len(derep_base.split('|checkv_provirus')) > 1:
        derep_base = derep_base.split('|checkv_provirus')[0]
    derep_reps.append(derep_base)

derep_reps_set = set(derep_reps)


for record in SeqIO.parse(input_fasta_gunzip, "fasta"):
    record_id_base = record.id
    if len(record_id_base.split('|provirus')) > 1:
        record_id_base = record_id_base.split('|provirus')[0]
    if len(record_id_base.split('|checkv_provirus')) > 1:
        record_id_base = record_id_base.split('|checkv_provirus')[0]
    if record_id_base in derep_reps_set:
        # save all sequences to specified file
        SeqIO.write(record, output_dir + '/' + record.id + '.fna', "fasta")


