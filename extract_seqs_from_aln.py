#!/usr/bin/env python
# Copyright (C) 2020 Sur Herrera Paredes

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from Bio import AlignIO, SeqIO
# from Bio.Seq import Seq
# from Bio.SeqRecord import SeqRecord
import os
import argparse


def process_arguments():
    # Read arguments
    parser_format = argparse.ArgumentDefaultsHelpFormatter
    parser = argparse.ArgumentParser(formatter_class=parser_format)
    required = parser.add_argument_group("Required arguments")

    # Define description
    parser.description = ("Takes a multiple sequence alignment file and "
                          "it ungaps it and returns a single file with "
                          "the original sequences.")

    # Define required arguments
    required.add_argument("--aln_file",
                          help=("Multiple sequence alignment file."),
                          required=True, type=str)

    # Define other arguments
    parser.add_argument("--outfile",
                        help=("Output file name. If left empty, then the "
                              "input file name is used such that if the "
                              "input file is '/path/to/file.ext', then "
                              "the outfile is 'file.<out_format>'."),
                        type=str,
                        default='')
    parser.add_argument("--in_format",
                        help=("Format of input multiple sequence alignment."),
                        type=str,
                        default="fasta")
    parser.add_argument("--out_format",
                        help=("Format for output sequence file."),
                        type=str,
                        default='fasta')

    # Read arguments
    print("Reading arguments")
    args = parser.parse_args()

    # Processing goes here if needed
    if args.outfile == '':
        basename = os.path.basename(args.aln_file)
        basename = os.path.splitext(basename)[0]
        args.outfile = '.'.join([basename, args.out_format])

    if os.path.isfile(args.outfile):
        raise FileExistsError("Output file {} already exists".format(args.outfile))

    return args

if __name__ == "__main__":
    args = process_arguments()

    # aln_file = "/home/sur/micropopgen/exp/2020/today3/og_alns/05D4K.fasta"
    # in_format = "fasta"
    # out_format = "fasta"
    # outfile = "testseqs/aln_seqs.fasta"

    # Read sequences
    with open(args.aln_file, 'r') as ih:
        Seqs = []
        aln = AlignIO.read(ih, args.in_format)
        print("Alignment length %i" % aln.get_alignment_length())
        for record in aln :
            record.seq = record.seq.ungap("-")
            Seqs.append(record)
    ih.close()

    # Write sequences
    with open(args.outfile, 'w') as oh:
        SeqIO.write(Seqs, oh, args.out_format)
    oh.close()
