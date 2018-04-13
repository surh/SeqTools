#!/usr/bin/env perl
# Script that takes an Illumina fastq file from JGI
# that contains both forward and reverse reads, and
# Generates two files, one with forward reads, and one
# with reverse reads.
# Usage:
#	$ fastq_split_pe_reads input out_prefix

use strict;
use warnings;
use Bio::SeqIO;

# Read options
my ($infile,$out_prefix) = @ARGV;

# Creat output streams
print "Creating output files...\n";
my $Fout = Bio::SeqIO->new(-format => 'fastq', -file => ">$out_prefix.forward.fastq");
my $Rout = Bio::SeqIO->new(-format => 'fastq', -file => ">$out_prefix.reverse.fastq");
#my ($Fout,$Rout);
#open($Fout,">$out_prefix.forward.fastq");
#open($Rout,">$out_prefix.reverse.fastq");

# Open input file
print "Opening input file...\n";
my $in = Bio::SeqIO->new(-format => 'fastq', -file => $infile);

my ($Fread,$Rread,$Fid,$Rid);
my $i = 0;
my $j = 0;
print "Splitting file...\n";
while (my $seq = $in->next_seq){
	my $id = $seq->id;
	#print "++$id\n";
	# If we are in the forward read
	if($id =~ /(.+)\/1$/){
		$Fid = $1;
		$Fread = $seq;
		#print "\tF==$Fid==\n";
	}elsif($id =~ /(.+)\/2$/){
		$Rid = $1;
		$Rread = $seq;
		#print "\tR==$Rid==\n";
		if($Fid eq $Rid){
			$Fout->write_fastq($Fread);
			$Rout->write_fastq($Rread);
			$Fid = $Rid = $Fread = $Rread = '';
			$j++;
		}else{
			print "Reverse read ($id) ($i) does not match forward ($Fid) read.\n"
		}


	}else{
		warn "Read id ($id) does not match expected pattern ($!)";
	}
	#last if $i++ > 200000;
	print "\tProcessed $i sequences...\n" if (($i++ % 100000) == 0);
}
print "\tProcessed $i sequences, and written $j pairs\n";

























