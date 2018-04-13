#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($infile,$outfile) = @ARGV;

die "Usage:\n\t\$ fasta2fasta.pl <infile.fastq> <outfile.fa>\n" unless -f $infile;

my $in = Bio::SeqIO->new(-format => 'fastq',-file => $infile);
open(OUT,'>',$outfile) or die $!;
my $i = 0;
while(my $Seq = $in->next_seq){
	my $id = $Seq->id;
	my $seq = $Seq->seq;
	print OUT ">$id\n$seq\n";
	$i++;
}
close OUT;

print "Wrote $i sequences.\n";


