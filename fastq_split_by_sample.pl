#!/usr/bin/env perl 

use strict;
use warnings;
use Bio::SeqIO;

my ($infile,$outdir) = @ARGV;

my %Outfiles;
mkdir $outdir unless -d $outdir;

my $in = Bio::SeqIO->new(-format => 'fastq', -file => $infile);
while(my $Seq = $in->next_seq){
	my $id = $Seq->id;
	my ($sample,@trash) = split(/_/,$id);
	if(!exists($Outfiles{$sample})){
		$Outfiles{$sample} = Bio::SeqIO->new(-file => ">$outdir/$sample.fastq", -format => 'fastq');
	}
	$Outfiles{$sample}->write_seq($Seq);
}

