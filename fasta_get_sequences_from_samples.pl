#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($infile,$samples,$outfile) = @ARGV;
my $usage_message = "\t\$ fasta_get_sequences_from_sample.pl <infile.fa> <samples.txt> <outfile.txt>\n";
die $usage_message unless (-f $infile && -f $samples);
my (%Samples);

open(SAMPLES,$samples) or die $!;
while(<SAMPLES>){
	chomp;
	my @line = split(/\t/,$_);
	my $id = $line[0];
	$Samples{$id} = 0;
}
close SAMPLES;

my $in = Bio::SeqIO->new(-file => $infile, -format => 'fasta');
open(OUT,'>',$outfile) or die $!;
while(my $Seq = $in->next_seq){
	my $id = $Seq->id;
	my $seq = $Seq->seq;
	my @header = split(/_/,$id);
	my $sample = $header[0];

	if(exists($Samples{$sample})){
		print OUT ">$id\n$seq\n";
		$Samples{$sample}++;
	}
}
close OUT;

print "$_\t$Samples{$_}\n" for keys %Samples;

