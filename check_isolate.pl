#!/usr/bin/env perl
# Usage:
#	$ check_isolates.pl <infile> <ref> outdir

use strict;
use warnings;

my $usage_msg = "Usage:\n\t\$ check_isolates.pl <infile> <ref> <outdir>";
my ($infile,$ref_file,$outdir) = @ARGV;
die "$usage_msg\n" unless -f $infile && -f $ref_file;

$/ = ">";
open(REF,$ref_file) or die "Can't open $ref_file ($!)";
my %Ref;
while(<REF>){
	chomp;
	next if $_ eq '';
	my @entry = split(/\n/,$_);
	my $id = shift @entry;
	my $seq = join("",@entry);
	my @header = split(/_/,$id);
	$id = $header[0];
	#print ">$id\n$seq\n";
	$Ref{$id} = $seq;
}
close REF;
#exit;


mkdir $outdir unless -d $outdir;
open(IN,$infile) or die "Can't open $infile ($!)";
while(<IN>){
	chomp;
	#print "hola\n";
	next if $_ eq '';
	my @entry = split(/\n/,$_);
	my $id = shift @entry;
	my $seq = join("",@entry);
	my @header = split(/_/,$id);
	my $db_id = $header[0];
	open(FA,'>',"$outdir/$id.fasta") or die "Can't create $outdir/$id.fasta \n";
	print FA ">${id}_candidate\n$seq\n";
	print FA ">${db_id}_ref\n$Ref{$db_id}\n";
	close FA;
	my $command = "clustalw -INFILE=$outdir/$id.fasta -QUIET -OUTFILE=$outdir/$id.aln";
	system($command);
}
close IN;



