#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($infile,$seqfile,$idcol,$groupcol,$suffix,$read,$outdir) = @ARGV;

$idcol--;
$groupcol--;
mkdir $outdir unless -d $outdir;
my %TABLE;
my %GROUPS;
my %OUT;
my %WRITTEN;
open(IN,$infile);
my $i = 0;
my $nam = 0;
print "Reading IDs\n";
while(<IN>){
	chomp;
	my @line = split(/\t/,$_);
	my $id = $line[$idcol];
	#print "$id\n";

	# Check the read number, it only works for one or two reads
	$id =~ s/[12]:N:0:([ACGT]{8})/$read:N:0:$1/;
	#print "\t$id\n";

	if ($line[$groupcol] !~ /^SC\d+/){
		$nam++;
		next;
	}

	$TABLE{$id} = $line[$groupcol];
	if(!exists($GROUPS{$line[$groupcol]})){
		$GROUPS{$line[$groupcol]} = 1;
		$WRITTEN{$line[$groupcol]} = 0;
		my $filename = $outdir . "/" . $line[$groupcol] . "." . $suffix . ".fastq";
		#print "==$filename==\n";
		$OUT{$line[$groupcol]} = Bio::SeqIO->new(-format => 'fastq', -file => ">$filename");
		print "\tCreated $filename\n";
	}else{
		$GROUPS{$line[$groupcol]}++;
	}
	$i++
}
print "Read $i reads\n";
print "Discarded $nam reads because of bad group\n";
close IN;


my $in = Bio::SeqIO->new(-format => 'fastq', -file => $seqfile);
$i = 0;
my $skipped = 0;
my $written = 0;
while (my $seq = $in->next_seq()){
	my $id = $seq->id();
	my $desc = $seq->desc();
	my $key = "$id $desc";
	if(exists($TABLE{$key})){
		#my $fh = $OUT{$TABLE{$key}}
		$OUT{$TABLE{$key}}->write_fastq($seq);
		#$fh->write_fastq($seq);
		$WRITTEN{$TABLE{$key}}++;
		$written++;
	}else{
		$skipped++;
	}
	#print "$key\t$TABLE{$key}\n"; 
	$i++;
}
print "Processed $i reads\n";
print "Wrote $written reads\n";
print "Skipped $skipped reads\n";

print "Summary:\n";
print "GROUP\tSEQIDS\tSEQS\tOUTFILE\n";
for (keys %OUT){
	print "$_\t$GROUPS{$_}\t$WRITTEN{$_}\t" . $OUT{$_}->file . "\n";
}

