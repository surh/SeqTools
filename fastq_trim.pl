#!/usr/bin/env perl
# Prints to STDOUT a tab delimited file with sequence lengths
# Usage:
#	$ fasta_trim.pl seqs.fa len out.fa

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

# Read arguments
my $usage = "To trim all sequences to the same length:\n\t\$ fasta_trim.pl -input <seqs.fastq> -length <length> -output <out.fastq>\n\nTo chop n bases at the end of each sequence:\n\t\$ fasta_trim.pl -input <seqs.fastq> -chop <n> -output <out.fastq>\n\nNOTE:sequences shorter than the desired length after triming or chopping are removed from the output.\n";
$usage .= "Other options:\n\t-fiveprime Remove from five prime.\n";
my $seqs_file = '';
my $len = 0;
my $outfile = '';
my $chop = 0;
my $help = '';
my $fiveprime = 0;

my $opts = GetOptions("input|infile|i=s" => \$seqs_file,
			"length|l=i" => \$len,
			"chop|c=i" => \$chop,
			"output|outfile|o=s" => \$outfile,
			"-fiveprime" => \$fiveprime,
			"h" => \$help);
die "$usage\n" if $help;
die "Input file ($seqs_file) not found.\n" unless -f $seqs_file;
die "Output file ($outfile) not provided.\n" unless $outfile;
die "One option of chop and length must be used (Use -h for help).\n" unless $len || $chop;
die "Only one option of chop and length must be used (Use -h for help).\n" if $len && $chop;

# Open query sequences file
my $Seqs = Bio::SeqIO->new( -file => "$seqs_file", -format => 'fastq');
#open(OUT,">$outfile") or die "Can't create $outfile ($!)";
my $out_fastq = Bio::SeqIO->new(-format => 'fastq', -file => ">$outfile");

# Search each query sequence
my ($i,$j) = 0;

while(my $query = $Seqs->next_seq()){
	my $seq = $query->seq;
	my $length = length $seq;
	$j++;

	my $start = 1;
	my $end = -1;
	if ($fiveprime){
		$end = $length;
		if($chop > 0 && $chop < $length){
			$start = $chop + 1;
		}elsif($len > 0 && $len <= $length){
			$start = $length - $len + 1;
		}
	}else{
		$start = 1;
		if($chop > 0 && $chop < $length){
			$end = $length - $chop;
		}elsif($len > 0 && $len <= $length){
			$end = $len;
		}
	}

	#print "==len:$length==$start--$end==\n";

	if($start <= $end){
		$out_fastq->write_fastq($query->trunc($start,$end));
		$i++;
	}


	#last if $i >= 10;
}

print "$j sequences processed. $i sequences trimmed.\n";


