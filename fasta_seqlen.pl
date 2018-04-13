#!/usr/bin/env perl
# Takes a fasta file and generates a contingecy table of sequence
# lengths.
# Usage:
#	$ fasta_seqlen.pl infile.fa bin_size outfile.txt

use strict;
use Bio::SeqIO;

# Read parameters and define primers
my ($ref_fasta,$bin_size,$outfile) = @ARGV;
my (@hist);

# Read file
my $in = Bio::SeqIO->new(-file => $ref_fasta, -format => 'fasta');
my $i = 0;
while (my $query = $in->next_seq()){
	my ($amplicon);
	my $seq = $query->seq();
	my $len = length($seq);
	my $bin = int($len / $bin_size);
	#print "$len,$bin\n";
	$hist[$bin]++; 
	$i++;
}

open (OUT,">$outfile") or die "Can't create $outfile ($!)";
my $j = 0;
for my $count (@hist){
	my $bin = $j*$bin_size;
	$count = 0 if !$count;
	print OUT "$bin\t$count\n";
	$j++;
	#print "$count\n";
}
close OUT;

print "$i sequences counted\n"

