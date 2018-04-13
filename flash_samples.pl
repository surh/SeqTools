#!/usr/bin/env perl
# flash_samples.pl <indir> <map> <outdir> 

use warnings;
use strict;

my ($indir,$map,$outdir) = @ARGV;
my (%barcode);

open(MAP,$map) or die $!;
while(<MAP>){
	chomp;
	my @line = split(/\t/,$_);
	chop $line[5];
	$barcode{$line[0]} = $line[5];
}
close MAP;

mkdir $outdir;
mkdir "$outdir/log";
for my $sample (keys %barcode){
	my $file1 ="$indir/${sample}_$barcode{$sample}_L001_R1_001.fastq";
	my $file2 ="$indir/${sample}_$barcode{$sample}_L001_R2_001.fastq";
	#print "$file1\n";

	my $out_prefix = "${sample}_$barcode{$sample}";

	my $command = "flash $file1 $file2 -m 30 -M 250 -x 0.25 -r 250 -f 282 -s 25 -o $out_prefix -d $outdir";
	$command = "bsub -o $outdir/log/${out_prefix}.log -e $outdir/log/${out_prefix}.error $command";
	print "Executing\n\t>$command\n";
	system($command);

	#last;
}


