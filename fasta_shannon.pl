#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;


my $infile = '';
my $outfile = '';
my $n = 5;

my $opts = GetOptions("input=s" => \$infile,
			"n=i" => \$n,
			"output=s" => \$outfile);
die unless -f $infile;
my $in = Bio::SeqIO->new(-file => $infile, -format => 'fasta');
open(OUT,'>',$outfile) or die $!;
while(my $query = $in->next_seq){
	my $id = $query->id;
	my $seq = $query->seq;
	#print length($seq) . "\n---\n";

	my %Freqs;
	for(my $i = 0; $i < length($seq) - ($n -1); $i++){
		#print "=" . substr($seq,$i,1) . "=\n";
		#print "---hola:$i---\n";
		my $word = substr($seq,$i,$n);
		#$profile->{$dint}++;
		if(exists($Freqs{$word})){
			$Freqs{$word}++;
		}else{
			$Freqs{$word} = 1;
		}
	}

	my $H = 0;
	#print "ID:$id\n";
	for (keys %Freqs){
		my $freq = $Freqs{$_} / (length($seq) - ($n - 1));
		$H += $freq * log2($freq);
		#print "\t$_\t$Freqs{$_}\t$freq\t$H\n";
	}
	$H *= -1 / $n;
	print OUT "$id\t$H\n";
	#last;
}


##SUBS
sub log2{
	my ($x) = @_;
	my $log2 = log($x) / log(2);
	return $log2;
}

