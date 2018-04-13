#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;

my ($input,$output,$help,$map);
my $idcol = 1;
my $barcodecol = 5;
my $frameshiftcol = 6;
my $skip = 1;
my $barcode2col = 7;

my $opts = GetOptions("input=s" => \$input,
			"output=s" => \$output,
			"map|m=s" => \$map,
			"idcol=i" => \$idcol,
			"frameshiftcol=i" => \$frameshiftcol,
			"barcodecol=i" => \$barcodecol,
			"barcode2col=i" => \$barcode2col,
			"help|man|?|h" => \$help);
my $usage_message = "Usage:\n\t\$ demultiplex_frameshifts.pl -input <input.fastq> -output <output.fasta>\n";
die "1:\n$usage_message" if $help;
die "2:\n$usage_message" unless -f $input;
die "3:\n$usage_message" unless $output;

# Read Map
open(MAP,$map) or die $!;
$idcol--;
$barcodecol--;
$frameshiftcol--;
my (%Map,%Count);
my $i = 0;
while(<MAP>){
	next unless $i++ >= $skip;
	chomp;
	my @line = split(/\t/,$_);
	my $barcode = $line[$barcodecol];
	chop($barcode);
	my $key = "$barcode.$line[$frameshiftcol]";
	$Map{$key} = $line[$idcol];
	$Count{$key} = 0;
}
close MAP;

my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
open(OUT,'>',$output) or die $!;
my $count = 0;
my $nomatch = 0;
my $badbarcode = 0;
print "Processing reads...\n";
while(my $Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id = $Seq->desc;
	
	#print "$id\n";
	my ($mt, $unique, $barcode_info) = split(/\s/,$id);
	#print "$mt=$unique=$barcode_info\n";
	my ($ft,$rt) = split(/-/,$mt);
	my ($t1,$t2,$t3,$barcode) = split(/:/,$barcode_info);


	my $flen = length($ft);
	my $rlen = length($rt);

	if ($flen >= 11 && $flen <= 16 && $rlen >= 5 && $rlen <= 10){
		$flen %= 2;
		$rlen %= 2;

		if($flen == 1 && $rlen == 0){
			my $key = "$barcode.oddF";
			print "$key\n";
			print OUT ">$Map{$key}_$Count{$key}\n$seq\n";
			$Count{$key}++;
		}elsif($flen == 0 && $rlen == 1){
			my $key = "$barcode.evenF";
			print OUT ">$Map{$key}_$Count{$key}\n$seq\n";
			$Count{$key}++;
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
print "$_\t$Count{$_}\n" foreach keys %Count;


