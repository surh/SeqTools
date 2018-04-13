#!/usr/bin/env perl
# qc_samples.pl <indir> <map> <outdir> 

use warnings;
use strict;

my ($indir,$map,$outdir) = @ARGV;
my (%barcode,%gccode);

open(MAP,$map) or die $!;
while(<MAP>){
	chomp;
	my @line = split(/\t/,$_);
	chop $line[5];
	$barcode{$line[0]} = $line[5];
	$gccode{$line[0]} = $line[8];
}
close MAP;

mkdir $outdir;
mkdir "$outdir/log";
my $i = 0;
my (@file_list,@id_list);
for my $sample (keys %barcode){
	my $file1 ="$indir/${sample}_$barcode{$sample}.extendedFrags.fastq";
	#my $out_prefix = "${sample}_$barcode{$sample}";

	if(-s $file1 > 0){
		push(@file_list,$file1);
		push(@id_list,$gccode{$sample});
	}

	#last if $i++ > 3;
	#last;
}

my $files = join(',',@file_list);
my $ids = join(',',@id_list);	
my $command = "split_libraries_fastq.py -i $files --sample_id $ids -o $outdir -m map.txt -q 19 --barcode_type 'not-barcoded'";
$command = "bsub -o $outdir/log/qc.log -e $outdir/log/qc.error $command";
print "Executing\n\t>$command\n";
system($command);
