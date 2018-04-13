#!/usr/bin/env perl
# Takes a fasta file and counts the number of
# ambiguous bases (N) per sequence
# Usage:
#	$ count.pl infile.fa outfile

use strict;
use warnings;
use Bio::SeqIO;

# Read parameters and define primers
my ($ref_fasta,$outfile) = @ARGV;

# Read file
my $in = Bio::SeqIO->new(-file => $ref_fasta, -format => 'fasta');
#open (OUT,">$outfile") or die "Can't create $outfile ($!)";
my $i = 0;
while (my $query = $in->next_seq()){

	my $seq = $query->seq();
	my $id = $query->id();

	$seq =~ s/[AGCT]//g;
	#print "$seq\n";
	my $ncount = length($seq);
	print "$ncount\n"
}
#close OUT;

print "$i sequences amplified\n"

