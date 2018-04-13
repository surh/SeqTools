#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

#my (%pnum_map);
my $outfile = '';
my $config = '';
my $splitchar = '_';
my $help = "Usage:\n>\$ map_samples.pl -config <config_file> -outfile <outfile> [-splitchar <_>]\n";

my $opts = GetOptions("config=s" => \$config,
			"outfile=s" => \$outfile,
			"splitchar=s" => \$splitchar);
die "$help\n" unless $outfile and $config;


open(CONFIG,$config) or die "Can't open $config ($!)";
open(OUT,'>',$outfile) or die "Can't create $outfile ($!)";
while(<CONFIG>){
	chomp;
	my ($barcode,$pnum);
	if ($_ =~ /<sample barcode="([ACGT]+)".*sample_id="(P\d+)"/){
		#print "$2\n";	
		$barcode = $1;
		$pnum = $2;
		#$pnum_map{$barcode} = $pnum;
		if ($_ =~ /fwd_file=\".*\/(.*)_${barcode}_L001_R1_001\.fastq\"/){
			my $sample = $1;
			my @samples = split(/$splitchar/,$sample);
			my $sample1 = $samples[0];
			my $sample2 = 'NA';
			$sample2 = $samples[1] if $samples[1];
			print OUT "$pnum\t$barcode\t$sample\t$sample1\t$sample2\n";
		}else{
			print "Current line did not mathc expected pattern. Could not extract sample.\n$_\n";
		}
	}
}
close CONFIG;
close OUT;
#print "$_\t$pnum_map{$_}\n" foreach keys %pnum_map;

