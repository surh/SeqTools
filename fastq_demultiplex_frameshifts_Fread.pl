#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

my ($indir,$help,$map);
my $outdir = "./";
my $idcol = 1;
my $barcodecol = 5;
my $frameshiftcol = 6;
my $skip = 1;

my $opts = GetOptions("indir=s" => \$indir,
			"outdir|o=s" => \$outdir,
			"map|n=s" => \$map,
			"idcol=i" => \$idcol,
			"frameshiftcol=i" => \$frameshiftcol,
			"barcodecol=i" => \$barcodecol,
			"help|h|?|man" => \$help);

my $usage_msg = "Usage:\n\t\$ fastq_demultiplex_frameshift.pl -indir <indir> -map <map.txt> -outdir <out>\n";
die $usage_msg if $help;
die "Can't find $indir\n" unless -d $indir;

# Read Map
open(MAP,$map) or die $!;
$idcol--;
$barcodecol--;
$frameshiftcol--;
my (%Map,%Count);
my $i = 0;
while(<MAP>){
	next unless $i++ >= $skip;
	chomp;
	my @line = split(/\t/,$_);
	my $barcode = $line[$barcodecol];
	chop($barcode);
	my $key = "$barcode.$line[$frameshiftcol]";
	$Map{$key} = $line[$idcol];
	$Count{$key} = 0;
}
close MAP;
#print "$_\t$Map{$_}\n" foreach keys %Map;

opendir(DIR,$indir) or die $!;
my @files = grep{ -f "$indir/$_" } readdir DIR;
#print "$_\n" foreach @files;

#die;
# Prepare output 
mkdir $outdir unless -d $outdir;
open(OUT,'>',"$outdir/demultiplexed_seqs.fasta") or die $!;
#my $out1 = Bio::SeqIO->new(-format => 'fastq', -file => ">$outdir/$seq1_file");

for my $file (@files){
	# Get input object
	my ($date,$barcode_ID,$barcode_seq,@trash) = split(/_/,$file);
	my $in1 = Bio::SeqIO->new(-format => 'fastq', -file => "$indir/$file");

	while(my $Seq1 = $in1->next_seq){
		my $seq1 = $Seq1->seq;
		my ($ft,$flen);
		if($seq1 =~ /^([AGCTN]{11,16})TCACTCCTACGGGAGGCAGCA([ACGT]+)$/){
			$ft = $1;
			$seq1 = $2;
			$flen = length($ft);
			$flen %= 2;
			if ($flen == 1){
				$flen = "oddF";
			}else{
				$flen = "evenF";
			}
			my $key = "$barcode_seq.$flen";
			print OUT ">$Map{$key}\n$seq1\n";
			$Count{$key}++;
			#print "$key\t$Map{$key}\n";
		}
	}
}

print "$_\t$Count{$_}\n" foreach keys %Count;






