#!/usr/bin/env perl
# Reads a fasta file and randomly determines whether a given sequence
# must be printed to output, by generating a random number.
# The user specifies a proportinon of desired sequences and the probability
# ensures this proportion is mantained
# Usage:
#	$ match_seqs.pl seqs.fa prob out.fa

use strict;
use warnings;
use Bio::SeqIO;

# Read arguments
my ($seqs_file,$prob,$outfile) = @ARGV;

# Open query sequences file
my $Seqs = Bio::SeqIO->new( -file => "$seqs_file", -format => 'Fasta');

# Create output file
open(OUT,">$outfile") or die "Can't create $outfile ($!)";

my $count = 0;
while(my $query = $Seqs->next_seq()){
	# Create a fasat file with current query.
	my $id = $query->id();
	my $seq = $query->seq();
	if (rand(1) < $prob){
		print OUT ">$id\n$seq\n";
		$count++;
	}
}
close OUT;

print "$count sequences written...\n";

