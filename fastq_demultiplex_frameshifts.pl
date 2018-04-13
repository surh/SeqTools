#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
#use File::Temp;

my ($seq1_file,$seq2_file,$help);
my $outdir = "./";

my $opts = GetOptions("seq1=s" => \$seq1_file,
			"seq2=s" => \$seq2_file,
			"outdir|o=s" => \$outdir,
			"help|h|?|man" => \$help);

my $usage_msg = "Usage:\n\t\$ fastq_demultiplex_frameshift.pl -seq1 <file1.fa> -seq2 <file2.fa> -outdir <out>\n";
die $usage_msg if $help;
die "Can't find $seq1_file\n" unless -f $seq1_file;
die "Can't find $seq2_file\n" unless -f $seq2_file;

my $in1 = Bio::SeqIO->new(-format => 'fastq', -file => $seq1_file);
my $in2 = Bio::SeqIO->new(-format => 'fastq', -file => $seq2_file);

mkdir $outdir unless -d $outdir;
my $out1 = Bio::SeqIO->new(-format => 'fastq', -file => ">$outdir/$seq1_file");
my $out2 = Bio::SeqIO->new(-format => 'fastq', -file => ">$outdir/$seq2_file");

#my $dir = File::Temp->newdir('inputsXXXXX',DIR => $outdir);
#my $dirname = $dir->dirname;
#my $outputs = File::Temp->newdir('outputsXXXXX',DIR => $outdir,CLEANUP => 0);
#my $outputsdir = $outputs->dirname;
while(my $Seq1 = $in1->next_seq){
	die "Number of sequences does not match between files\n" unless my $Seq2 = $in2->next_seq;
	# Gather info
	#my $id1 = $Seq1->id;
	#my $id2 = $Seq2->id;
	my $seq1 = $Seq1->seq;
	my $seq2 = $Seq2->seq;

	if($seq1 =~ /^([AGCTN]{11,16})TCACTCCTACGGGAGGCAGCA/){
		
	}
	if($seq2 =~ /^([AGCTN]{11,16})TCACTCCTACGGGAGGCAGCA/){
		
	}

	$out1->write_seq($Seq1);
	$out2->write_seq($Seq2);

}


##### SUBROUTINES #########




