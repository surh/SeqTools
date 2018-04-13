#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my $usage = "\$ fasta_qc.pl <input.fa> <output.fa>\n";
my $input = shift(@ARGV) or die $usage;
my $output = shift(@ARGV) or die $usage;

my $in = Bio::SeqIO->new(-file => $input,-format => 'fasta');
open(OUT,'>',$output) or die "Can't create $output ($!)";
#open(TEMP,'>','temp.fa') or die "Can't create $output ($!)";
my ($i,$j) = 0;
while(my $Seq = $in->next_seq()){
	my $id = $Seq->id;
	my $seq = $Seq->seq;
	if ($seq =~ /^[ACTG]+$/i){
		print OUT ">$id\n$seq\n";
		$i++;
	}#else{
	#	print TEMP ">$id\n$seq\n";
	#}
	$j++;
}
close OUT;

print "Processed $j sequences. Wrote $i sequences.\n";



