#!/usr/bin/env perl

use strict;
use warnings;
use Pod::Usage;
use Getopt::Long;
use Bio::SeqIO;
use XML::Simple;

my ($input,$output,$help,$config,$map);
my $idcol = 1;
my $barcodecol = 5;
my $frameshiftcol = 6;
my $barcode2col = 7;
my $skip = 1;
my $mode = 'se';
my $class = 'consensus';

my $opts = GetOptions("input=s" => \$input,
			"output=s" => \$output,
			"map|m=s" => \$map,
			"idcol=i" => \$idcol,
			"frameshiftcol=i" => \$frameshiftcol,
			"barcodecol=i" => \$barcodecol,
			"barcode2col=i" => \$barcode2col,
			"mode=s" => \$mode,
			"class=s" => \$class,
			"config=s" => \$config,
			"help|man|?|h" => \$help);
my $usage_message = "Usage:\n\t\$ demultiplex_frameshifts.pl -input <input.fastq> -output <output.fasta> -map <map.txt> -config <config.xml>\n";
die "1:\n$usage_message" if $help;
die "2:\n$usage_message" unless -f $input && -f $map && -f $config;
die "3:\n$usage_message" unless $output;
die "Mode has to be se" unless $mode eq 'se';

#print "Hello\n";

my ($map_ref,$count_ref) = read_map($map,$idcol,$barcodecol,$frameshiftcol,$barcode2col,$skip);
my $barcode_ref = read_config($config);

# Open and read file
my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
open(OUT,'>',$output) or die "Can't create output file ($!)";
my $count = 0;
my $nomatch = 0;
my $badframeshift = 0;
print "Processing reads...\n";
while(my $Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id;
	if($class eq 'consensus'){
		$id = $Seq->id;
	}elsif($class eq 'categorizable'){
		$id = $Seq->desc;
	}else{
		die "Only consensus and categorizable are valid classes ($class).";
	}
	#print "$seq\n";
	#print "$id\n";

	my ($mt,$barcode) = get_mt_and_barcode($id,$mode,$class,$barcode_ref);
	#print "$mt\n";
	#next;

	my $mtlen = length($mt);
	#print "$id\t$mtlen\n";
	if ($mtlen >= 11 && $mtlen <= 16){
		#print "hello2\n";
		$mtlen %= 2;
		my ($frameshift,$barcode2);

		if($mtlen == 1){
			$frameshift = 'oddF';
		}elsif($mtlen == 0){
			$frameshift = 'evenF';
		}
		#print "$id\t$frameshift\n";

		if($mt =~ /([ACGT]{4,9})(TGA|ACT)([ACGT]{4})/){
			$barcode2 = $2;
			my $key = "$barcode.$frameshift.$barcode2";
			print OUT ">$map_ref->{$key}_$count_ref->{$key}\n$seq\n";
			$count_ref->{$key}++;
		}else{
			$nomatch++;
		}
	}else{
		$badframeshift++;
	}

	$count++;
	print "\tProcessed $count reads\n" if (($count % 50000) == 0);
}

close OUT;
print "Processed $count reads\n";
print "$nomatch reads out of $count did not match the barcode2\n";
print "$badframeshift reads out of $count had an incorrect molecule tag length.\n";
print "$map_ref->{$_}\t$count_ref->{$_}\n" foreach keys %{$count_ref};

################## SUBROUTINES #####################
sub get_mt_and_barcode{
	my ($id,$mode,$class,$barcode_ref) = @_;
	my ($sample_id,$mt,$barcode);

	if($mode eq 'se' && $class eq 'consensus'){
		my ($info,$barcodelabel,$c_score,$depth) = split(/;/,$id);
		($sample_id,$mt) = split(/_/,$info);
		$barcode = $barcode_ref->{$sample_id};
	}elsif($mode eq 'se' && $class eq 'categorizable'){
		#print "$id\n";
		my ($t1,$t2,$t3) = split(/\s/,$id);
		$mt = $t1;
		my ($t4,$t5,$t6,$t7) = split(/:/,$t3);
		$barcode = $t7;
		#print "$mt\t$barcode\n";

	}else{
		die "Only se  and consensus implemented at this time";
	}

	return($mt,$barcode);
}

sub read_map{
	my ($map,$idcol,$barcodecol,$frameshiftcol,$barcode2col,$skip) = @_;
	# Read Map
	open(MAP,$map) or die $!;
	$idcol--;
	$barcodecol--;
	$frameshiftcol--;
	$barcode2col--;
	my (%Map,%Count);
	my $i = 0;
	while(<MAP>){
		next unless $i++ >= $skip;
		chomp;
		my @line = split(/\t/,$_);
		my $barcode = $line[$barcodecol];
		chop($barcode);
		my $key = "$barcode.$line[$frameshiftcol].$line[$barcode2col]";
		$Map{$key} = $line[$idcol];
		$Count{$key} = 0;
	}
	close MAP;

	return(\%Map,\%Count)
}

sub read_config{
	my ($file) = @_;
	my $config_ref = XML::Simple->new()->XMLin($file);

	my %Barcode;
	for my $sample (@{$config_ref->{'sample'}}){
		#my @keys = keys %{$sample};
		my $sample_id = $sample->{'sample_id'};
		my $barcode = $sample->{'barcode'};
		#print "$sample_id\t$barcode\n";
		$Barcode{$sample_id} = $barcode;
	}
	return(\%Barcode);
}


