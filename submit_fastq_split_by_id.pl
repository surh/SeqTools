#!/usr/bin/env perl

use strict;
use warnings;

my ($indir,$seqdir,$outdir,$suffix,$logdir) = @ARGV;
my $bin = "/proj/dangl_lab/bin/SeqTools/fastq_split_by_id.pl";

# Read files with readids
opendir(DIR,$indir) or die $!;
my @files = grep{-f "$indir/$_"} readdir DIR;
closedir DIR;

# Read raw reads files
opendir(RAW,$seqdir) or die $!;
my @rawfiles = grep{-f "$seqdir/$_"} readdir RAW;
closedir RAW;
#print "@rawfiles\n";

# Get R1 files
my @R1 = grep{$_ =~ /R1_001.fastq$/} @rawfiles;
#print "@R1\n";

# Get R2 files
my @R2 = grep{$_ =~ /R2_001.fastq$/} @rawfiles;


my $barcode = '';
my @COMMANDS;
for $barcode (@files){
	#print "$barcode\n";
	my @r1_file = grep{$_ =~ /_${barcode}_L001_R1_001\.fastq/} @R1;
	my @r2_file = grep{$_ =~ /_${barcode}_L001_R2_001\.fastq/} @R2;

	#print "@r1_file\n";
	#print "@r2_file\n";


	#print "$r1_file[0]\n";

	die if (scalar @r1_file) != 1 || (scalar @r2_file) != 1;

	my $command1 = "$bin $indir/$barcode $seqdir/$r1_file[0] 1 2 R1.$suffix 1 $outdir";
	$command1 = "bsub -o $logdir/$suffix.$barcode.R1.log -e $logdir/$suffix.$barcode.R1.err -J $suffix.$barcode.R1 $command1";

	my $command2 = "$bin $indir/$barcode $seqdir/$r2_file[0] 1 2 R2.$suffix 2 $outdir";
	$command2 = "bsub -o $logdir/$suffix.$barcode.R2.log -e $logdir/$suffix.$barcode.R2.err -J $suffix.$barcode.R2 $command2";

	push(@COMMANDS,$command1);
	push(@COMMANDS,$command2);
}

for (@COMMANDS){
	print "Executing:\n\t>$_\n";
	my $out = system($_);
	print "\tStatus=$out\n";
}
