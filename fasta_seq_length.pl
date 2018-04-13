#!/usr/bin/env perl
# Prints to STDOUT a tab delimited file with sequence lengths
# Usage:
#	$ match_seqs.pl seqs.fa out.txt

use strict;
use warnings;
use Bio::SeqIO;

# Read arguments
my ($seqs_file) = @ARGV;

# Open query sequences file
my $Seqs = Bio::SeqIO->new( -file => "$seqs_file", -format => 'Fasta');


# Search each query sequence
while(my $query = $Seqs->next_seq()){
	# Create a fasat file with current query.
	my $id = $query->id();
	my $seq = $query->seq();
	my $length = length($seq);
	print "$id\t$length\n";
}

