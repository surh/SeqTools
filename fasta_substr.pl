#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($infile, $start, $end, $outfile) = @ARGV;

my $in = Bio::SeqIO->new(-file => $infile, -format => 'fasta') or die $!;
open(OUT,'>', $outfile) or die "Can't create ($!)";
my ($Seq, $length);
if($end < $start){
	die "Wrong params\n";
}else{
	$length = $end - $start + 1;
	$start--;
}

while($Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id = $Seq->id;

	$seq = substr($seq, $start, $length);
	print OUT ">$id\n$seq\n";
}
close OUT;
