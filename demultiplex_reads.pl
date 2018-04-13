#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;

my ($map,$input,$summary,$output,$help);
my $idcol = 1;
my $barcodecol = 2;
my $barcode2col = 4;

my $opts = GetOptions("input=s" => \$input,
			"tab=s" => \$map,
			"summary=s" => \$summary,
			"output=s" => \$output,
			"help|map" => \$help);

#print "==$map===\n";
#print "==$input===\n";

my %pnum;
open(SUM,$summary) or die $!;
my $status = 0;
while(<SUM>){
	chomp;
	if ($_ =~ /^#/){
		$status = 1;
		next;
	}
	next unless $status;
	my @line = split(/\t/,$_);
	my $pnum = $line[1];
	my @name = split(/_/,$line[0]);
	my $bc1 = $name[0];
	my $bc2 = $name[1];
	$bc2 = 'NA' if $bc2 =~/^[ACGT]+$/;
	$pnum{'bc1'}->{$pnum} = $bc1;
	$pnum{'bc2'}->{$pnum} = $bc2;
}
print "Processed summary...\n";

#for my $key (keys %pnum){
#	print "$key=>$_=>$pnum{$key}->{$_}\n" foreach keys %{$pnum{$key}};
#}
#die;

my (%Map);
open(MAP,$map) or die "Can't open $map ($!)";
$idcol--;
$barcodecol--;
$barcode2col--;
while(<MAP>){
	chomp;
	my @line = split(/\t/,$_);
	#$Map{$line[$idcol]} = [$line[$barcodecol], $line[$barcode2col]];
	$Map{$line[$idcol]} = "$line[$barcodecol].$line[$barcode2col]";
	#print "$Map{$line[0]}->[1]\n";
}
close MAP;
print "Processed map...\n";


my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
open(OUT,'>',$output) or die $!;
my $count = 0;
my $nomatch = 0;
my $badbarcode = 0;
print "Processing reads...\n";
while(my $Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id = $Seq->id;
	
	my ($pnum,$mt) = split(/_/,$id);
	my ($ft,$rt) = split(/-/,$mt);
	$rt = $1 if $rt =~ /^([ACGT]+);/;

	#print "$id=>$ft-$rt\n";
	if($ft =~ /([ACGT]{4,9})(TGA|ACT)([ACGT]{4})/){
		#print "($1)($2)($3)\n";
		my $demultiplex = $2;
		if($demultiplex eq 'TGA'){
			my $sample_id = $pnum{'bc1'}->{$pnum};
			print OUT ">${sample_id}_$mt\n$seq\n";
			#print OUT ">$Map{$pnum}->[0]_$mt\n$seq\n";
		}elsif($demultiplex eq 'ACT'){
			my $sample_id = $pnum{'bc2'}->{$pnum};
			print OUT ">${sample_id}_$ft-$rt\n$seq\n";
			#print OUT ">$Map{$pnum}->[1]_$mt\n$seq\n";
		}else{
			$badbarcode++;
		}
	}else{
		$nomatch++;
	}

	#print "$id=>$ft-$rt\n";
	#last if ++$count >= 100;
	$count++;
	print "\tProcessed $count reads\n" if (($count % 50000) == 0);
}

close OUT;
print "$nomatch reads out of $count did not match\n";
print "$badbarcode reads out of $count had the wrong 3 letter barcode\n";





