#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;

my ($input,$output,$help);

my $opts = GetOptions("input=s" => \$input,
			"output=s" => \$output,
			"help|map" => \$help);
my $usage_message = "Usage:\n\t\$ demultiplex_frameshifts.pl -input <input.fastq> -output <output.fasta>\n";
die "$usage_message" if $help;
die "$usage_message" unless -f $input;
die "$usage_message" unless $output;

#print "==$map===\n";
#print "==$input===\n";


my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
open(OUT,'>',$output) or die $!;
my $count = 0;
my $nomatch = 0;
my $badbarcode = 0;
print "Processing reads...\n";
while(my $Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id = $Seq->id;

	my ($unique, $barcode, $c_score, $depth) = split(/;/,$id);
	my ($pnum,$mt) = split(/_/,$unique);
	my ($ft,$rt) = split(/-/,$mt);

	my $flen = length($ft);
	my $rlen = length($rt);

	if ($flen >= 11 && $flen <= 16 && $rlen >= 5 && $rlen <= 10){
		$flen %= 2;
		$rlen %= 2;

		if($flen == 1 && $rlen == 0){
			print OUT ">$pnum.oddF_$mt\n$seq\n";
		}elsif($flen == 0 && $rlen == 1){
			print OUT ">$pnum.evenF_$mt\n$seq\n";
		}else{
			$nomatch++;
		}
	}else{
		$badbarcode++;
	}

	$count++;
	print "\tProcessed $count reads\n" if (($count % 50000) == 0);
}

close OUT;
print "Processed $count reads\n";
print "$nomatch reads out of $count did not match\n";
print "$badbarcode reads out of $count had an incorrect molecule tag length.\n";


