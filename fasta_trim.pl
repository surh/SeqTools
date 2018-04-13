#!/usr/bin/env perl
# Prints to STDOUT a tab delimited file with sequence lengths
# Usage:
#	$ fasta_trim.pl seqs.fa len out.fa

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

# Read arguments
my $usage = "Trim from 3' end until final length:\n";
$usage .= "\t\$ fasta_trim.pl -i <seqs.fa> -l <len> -o <out.fa>\n";
$usage .= "Trim from 5' end until final length:\n";
$usage .= "\t\$ fasta_trim.pl -i <seqs.fa> -l <len> -o <out.fa> -fiveprime\n";
$usage .= "\nNOTE: STILL NEED TO IMPLEMENT TRIMMING A SPECIFIC NUMBER OF BASES\n";
$usage .= "\nBy Sur from Dangl Lab. Distributed under GPL-3\n";
#my $seqs_file = shift(@ARGV) or die $usage;
#my $len = shift(@ARGV) or die $usage;
#my $outfile = shift(@ARGV) or die $usage;

my $seqs_file = '';
my $len = 0;
my $outfile = '';
my $fiveprime = 0;
my $help = '';

my $opts = GetOptions("infile|i=s" => \$seqs_file,
			"length|l=i" => \$len,
			"outfile|o=s" => \$outfile,
			"fiveprime|f" => \$fiveprime,
			"help|h|man" => \$help);

die $usage if $help;
die $usage unless -f $seqs_file;



# Open query sequences file
my $Seqs = Bio::SeqIO->new( -file => "$seqs_file", -format => 'Fasta');
open(OUT,">$outfile") or die "Can't create $outfile ($!)";

# Search each query sequence
my $i = 0;
my $total = 0;
while(my $query = $Seqs->next_seq()){
	# Create a fasat file with current query.
	my $id = $query->id();
	my $seq = $query->seq();
	my $length = length($seq);
	if ($length >= $len){
		if($fiveprime){
			$seq = substr($seq,$length - $len);
		}else{
			$seq = substr($seq,0,$len);
		}
		print OUT ">$id\n$seq\n";
		$i++;
	}
	$total++;
}
close OUT;

print "$total sequences processed.\n";
print "$i sequences trimmed.\n";


