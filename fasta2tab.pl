#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;

my ($infile,$outfile) = '';
my $trim = 0;

my $opts = GetOptions("infile|i=s" => \$infile,
			"outfile|o=s" => \$outfile,
			"trim|t=i" => \$trim);

die "Usage:\tfasta2tab.pl -i infile -o outfile\n\tfasta2tab.pl -i infile -o outfile -t trim_length\n" unless -f $infile && $outfile;

my $new = Bio::SeqIO->new(-format => 'fasta',-file => $infile);
open(OUT,">$outfile") or die "Can't create $outfile ($!)";
while(my $Seq = $new->next_seq){
	my $id = $Seq->id;
	my $seq = $Seq->seq;
	if($trim > 0){
		$seq = substr($seq,0,$trim);
	}
	print OUT "$id\t$seq\n";
}
close OUT;


