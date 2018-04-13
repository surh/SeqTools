#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;

my ($seqs_file, $map_file, $sufix, $outfile) = @ARGV;
my $usage = "Usage:\n\t>process_seq_plate.pl <infile.fa> <map.txt> <sufix> <outfile.fa>\n";

die $usage unless -f $seqs_file && -f $map_file;

open(MAP,$map_file) or die $!;
my %Map;
while(<MAP>){
	chomp;
	my @line = split(/\t/,$_);
	next if $line[0] eq '<>';
	my $key = shift @line;
	$Map{$key} = [];
	my $i = 0;
	for my $cell (@line){
		$Map{$key}->[$i] = $cell unless $cell eq '';	# skip empty cells;
		#print "$key\[$i\] => $Map{$key}->[$i]\n" unless $cell eq '';
		$i++;
	}
}
close MAP;
#die;

my $in = Bio::SeqIO->new(-file => $seqs_file, -format => 'fasta') or die $!;
open(OUT,'>',$outfile) or die $!;
while(my $query = $in->next_seq()){
	my $id = $query->id;
	my @ID = split(/_/,$id);
	my $well = $ID[3];
	#print "$well\n"
	die unless $well =~ /\d\d[ABCDEFGH]/;
	my $col = substr($well,0,2);
	my $row = substr($well,2);
	my $pos = $col - 1;

	# print only sequences in the Map
	if (exists($Map{$row}->[$pos])){
		#print "$well=>$col,$row\t$pos\t$Map{$row}->[$pos]\n";
		my $newname = $Map{$row}->[$pos];
		$newname .= $sufix;
		my $seq = $query->seq;
		print OUT ">$newname\n$seq\n";
	}

}
close OUT;

