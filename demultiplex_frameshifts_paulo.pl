#!/usr/bin/env perl
# This script demultiplexes categorizable reads using Paulo's primers.
# These primers have no molecule tags (ie no ambiguous bases), and
# the smaller frameshifst can be zero.
#
# Each sample is sequenced with only one frameshift combination on each
# primer
#
# The categorizable file must be a fastq file from MTToolbox.
#
# The demultiplexing map, should include the frameshift length of each primer
# and the frameshift sequence of each primer.
#
# There is no inner barcode.

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;

# Read params and/or print help.
my ($input,$output,$help,$map);
my $idcol = 5;
my $barcodecol = 13;
my $Ffslencol = 8;
my $Ffsseqcol = 9;
my $Rfslencol = 10;
my $Rfsseqcol = 11;
my $skip = 1;
my $chomp_barcode = 0;
my $opts = GetOptions("input=s" => \$input,
			"output=s" => \$output,
			"map|m=s" => \$map,
			"idcol=i" => \$idcol,
			"barcodecol=i" => \$barcodecol,
			"Ffslencol=i" => \$Ffslencol,
			"Ffsseqcol=i" => \$Ffsseqcol,
			"Rfslencol=i" => \$Rfslencol,
			"Rfsseqcol=i" => \$Rfsseqcol,
			"chomp_barcode" => \$chomp_barcode,
			"skip=i" => \$skip,
			"help|man|?|h" => \$help);
my $usage_message = "Usage:\n\t\$ demultiplex_frameshifts.pl -input <input.fastq> -map <map.txt> -output <output.fasta>\n";
die "1:\n$usage_message" if $help;
die "2:\n$usage_message" unless -f $input;
die "3:\n$usage_message" unless -f $map;
die "4:\n$usage_message" unless $output;

mkdir $output unless -d $output;

# Read Map
open(MAP,$map) or die $!;
$idcol--;
$barcodecol--;
$Ffslencol--;
$Ffsseqcol--;
$Rfslencol--;
$Rfsseqcol--;
my (%Map,%Count,%Outfile);
my $i = 0;
while(<MAP>){
	next unless $i++ >= $skip;
	chomp;
	my @line = split(/\t/,$_);
	my $barcode = $line[$barcodecol];
	chop($barcode) if $chomp_barcode;
	my $key = "$barcode.$line[$Ffslencol].$line[$Rfslencol]";
	my $id = $line[$idcol];
	#print "id => $line[$idcol], Ffs => $line[$Ffsseqcol], Rfs => $line[$Rfsseqcol]\n";
	$Map{$key} = {id => $id, Ffs => $line[$Ffsseqcol], Rfs => $line[$Rfsseqcol]};
	$Count{$key} = 0;
	$Outfile{$id} = Bio::SeqIO->new(-format => 'fastq', -file => ">$output/$id.fastq");
	#print "$Map{$key}->{id}\n";
	#print "$key\n";
}
close MAP;

#print "$_=>$Map{$_}->{id}\t$Map{$_}->{Ffs}\t$Map{$_}->{Rfs}\n" foreach keys %Map;
#print "$_=>$Map{$_}{id}\n" foreach keys %Map;
#die;

my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
my $count = 0;
my $nomatch = 0;
my $badbarcode = 0;
my $badfslen = 0;
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
	$ft = '' if $flen == 0;
	$rt = '' if $rlen == 0;

	#print "$id\t$flen\t$rlen\n";

	# If lengthof frameshifts is within the expected length
	if ($flen >= 0 && $flen <= 5 && $rlen >= 0 && $rlen <= 5){
		my $key = "$barcode.$flen.$rlen";

		# If key has been defined
		if(exists($Map{$key})){
			
			# Check sequence
			my $Fexpected = '';
			my $Rexpected = '';
			$Fexpected = $Map{$key}->{Ffs} if $flen > 0;
			$Rexpected = $Map{$key}->{Rfs} if $rlen > 0;
			
			#print "$key\t$Map{$key}->{id}\t==$ft==-==$rt==\n";
			if($Fexpected eq $ft && $Rexpected eq $rt){
				$Outfile{$Map{$key}->{id}}->write_seq($Seq);
				$Count{$key}++;
			}else{
				$badbarcode++;
			}
		}else{
			$nomatch++;
		}
	}else{
		$badfslen++;
	}

	$count++;
	print "\tProcessed $count reads\n" if (($count % 50000) == 0);
}

print "Processed $count reads\n";
print "$nomatch reads out of $count did not match any predefined frameshift combination.\n";
print "$badbarcode reads out of $count had an incorrect molecule frameshift sequence.\n";
print "$badfslen reads out of $count did not have a frameshift in the expected length range\n";
print "$_\t$Map{$_}->{id}\t$Count{$_}\n" foreach keys %Count;


