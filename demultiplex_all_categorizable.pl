#!/usr/bin/env perl

#    (C) Copyright 2013-2016 Sur Herrera Paredes
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This script takes a demultiplexed 'categorizable' reads fastq file from MT-Toolbox,
# and demultiplex the reads. The reads on the 'categorizable' file are already split
# by index. This script looks at the inner barcode and frameshift for further demultiplexing the reads.

# It can also be used to extract the IDs of the original reads to keep.

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
my $chopbarcode2 = 0;
my $mode = 'parity';
my $ids_only = 0;

my $opts = GetOptions("input=s" => \$input,
			"output=s" => \$output,
			"map|m=s" => \$map,
			"idcol=i" => \$idcol,
			"frameshiftcol=i" => \$frameshiftcol,
			"barcodecol=i" => \$barcodecol,
			"barcode2col=i" => \$barcode2col,
			"chopbarcode2" => \$chopbarcode2,
			"mode=s" => \$mode,
			"idsonly" => \$ids_only,
			"help|man|?|h" => \$help);
my $usage_message = "Usage:\n\t\$ demultiplex_all_categorizable.pl -input <input.fastq> -output <output.fasta>\n";
die "1:\n$usage_message" if $help;
die "2:\n$usage_message" unless -f $input;
die "3:\n$usage_message" unless $output;

# The first step is to create a key that indicates which barcodes
# and frameshift scheme is used for each sample.
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
	chop($barcode) if $chopbarcode2;

	# This implelens a check, if frameshiftcol is 0 or a negative number,
	# then this will it will not be considered.
	my $frameshift = 'NA';
	$frameshift = $line[$frameshiftcol] if $frameshiftcol >= 0;

	my $barcode2 = 'NA';
	$barcode2 = $line[$barcode2col] if $barcode2col >= 0;

	my $key = "$barcode.$frameshift.$barcode2";
	$Map{$key} = $line[$idcol];
	#print "$key=>$Map{$key}\n";
	$Count{$Map{$key}} = 0;
	$Count{'NA'} = 0;
}
close MAP;

my $in = Bio::SeqIO->new(-format => 'fastq', -file => $input);
my $OUT;
open($OUT,'>',$output) or die $!;
my $count = 0;
my $nomatch = 0;
my $badbarcode = 0;
my $badbarcode2 = 0;
my $sample = '';
print "Processing reads...\n";
while(my $Seq = $in->next_seq){
	my $seq = $Seq->seq;
	my $id = $Seq->desc;
	
	#print "$id\n";
	my ($mt, $unique, $barcode_info) = split(/\s/,$id);
	#print "$mt=$unique=$barcode_info\n";
	my ($ft,$rt) = split(/-/,$mt);
	my ($t1,$t2,$t3,$barcode) = split(/:/,$barcode_info);

	$sample = '';
	my $flen = length($ft);
	my $rlen = length($rt);

	if ($flen >= 11 && $flen <= 16 && $rlen >= 5 && $rlen <= 10){
		my ($barcode2);
		#$flen %= 2;
		#$rlen %= 2;

		if($barcode2col < 0){
			$barcode2 = 'NA';
		}elsif($ft =~ /([ACGT]{4,9})(TGA|ACT)([ACGT]{4})/){
			$barcode2 = $2;
			if($barcode2 eq 'TGA'){
				$barcode2 = 'bc1';
			}else{
				$barcode2 = 'bc2';
			}
		}else{
			$badbarcode2++;
			$count++;
			next;
		}

		if($frameshiftcol < 0){
			my $key = "$barcode.NA.$barcode2";
			#print "$key=>$Map{$key}\n";
			$Map{$key} = 'NA' unless exists($Map{$key});
			print $OUT ">$Map{$key}_$Count{$Map{$key}}\n$seq\n" unless $ids_only;
			$Count{$Map{$key}}++;
			$sample = $Map{$key}

		}elsif($mode eq 'parity'){
			$sample = map_by_parity($flen,$rlen,$seq,$barcode,$barcode2,\%Map,\%Count,\$nomatch,$OUT,$ids_only);
		}elsif($mode eq 'order'){	
			$sample = map_by_order($flen,$rlen,$seq,$barcode,$barcode2,\%Map,\%Count,\$nomatch,$OUT,$ids_only);
		}else{
			die "Mode ($mode) not implemented. Must be 'parity' or 'order'.\n";
		}
		
	}else{
		$badbarcode++;
	}

	$count++;
	print $OUT "$unique $barcode_info\t$sample\t$barcode\n" if $ids_only && $sample ne '';
	print "\tProcessed $count reads\n" if (($count % 50000) == 0);
}

close $OUT;
print "Processed $count reads\n";
print "$badbarcode2 reads had a wrong inner barcode.\n";
print "$nomatch reads out of $count did not match\n";
print "$badbarcode reads out of $count had an incorrect molecule tag length.\n";
print "$Map{$_}\t$_\t$Count{$Map{$_}}\n" foreach keys %Map;

### SUBROUTINES

sub map_by_parity{
	my ($flen,$rlen,$seq,$barcode,$barcode2,$Map_ref,$Count_ref,$nomatch_ref,$out_fh,$ids_only) = @_;
	$flen %= 2;
	$rlen %= 2;
	if($flen == 1 && $rlen == 0){
		my $key = "$barcode.oddF.$barcode2";
		#print "$key\n";
		$Map_ref->{$key} = 'NA' unless exists($Map_ref->{$key});
		print $out_fh ">$Map_ref->{$key}_$Count_ref->{$Map_ref->{$key}}\n$seq\n" unless $ids_only;
		$Count_ref->{$Map_ref->{$key}}++;
		return($Map_ref->{$key}) if $ids_only;
	}elsif($flen == 0 && $rlen == 1){
		my $key = "$barcode.evenF.$barcode2";
		#print "$key\n";
		$Map_ref->{$key} = 'NA' unless exists($Map_ref->{$key});
		print $out_fh ">$Map_ref->{$key}_$Count_ref->{$Map_ref->{$key}}\n$seq\n" unless $ids_only;
		$Count_ref->{$Map_ref->{$key}}++;
		return($Map_ref->{$key}) if $ids_only;
	}else{
		$$nomatch_ref++;
		return('')
	}
}



sub map_by_order{
	my ($flen,$rlen,$seq,$barcode,$barcode2,$Map_ref,$Count_ref,$nomatch_ref,$out_fh,$ids_only) = @_;
	$flen -= 10;
	$rlen -= 4;

	if($flen <= 3 && $rlen > 3){
		my $key = "$barcode.firstF.$barcode2";
		#print "$key\n";
		$Map_ref->{$key} = 'NA' unless exists($Map_ref->{$key});
		print $out_fh ">$Map_ref->{$key}_$Count_ref->{$Map_ref->{$key}}\n$seq\n" unless $ids_only;
		$Count_ref->{$Map_ref->{$key}}++;
		return($Map_ref->{$key}) if $ids_only;
	}elsif($flen >= 4 && $rlen < 4 ){
		my $key = "$barcode.lastF.$barcode2";
		#print "$key\n";
		$Map_ref->{$key} = 'NA' unless exists($Map_ref->{$key});
		print $out_fh ">$Map_ref->{$key}_$Count_ref->{$Map_ref->{$key}}\n$seq\n" unless $ids_only;
		$Count_ref->{$Map_ref->{$key}}++;
		return($Map_ref->{$key}) if $ids_only;
	}else{
		$$nomatch_ref++;
	}
}

