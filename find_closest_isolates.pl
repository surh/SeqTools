#!/usr/bin/env perl

use strict;
use warnings;

my ($infile,$outfile) = @ARGV;
my $collection1 = '/home/sur/rhizogenomics/experiments/2015/2015-05-19.ornlunccollections/db/final_database.fa';
my $collection2 = '/home/sur/rhizogenomics/experiments/2015/2015-05-19.ornlunccollections/db/all_ornl_seqs_reoriented.fa';
#my $collection1 = '/home/sur/rhizogenomics/experiments/2015/2015-05-19.ornlunccollections/db/sequenced_unc.fa';
#my $collection2 = '/home/sur/rhizogenomics/experiments/2015/2015-05-19.ornlunccollections/db/sequenced_ornl.fa';
my $minlen = 500;
my $exclude = 'SUR';
my $eval = 0.00001;
my $perc_identity = 97;
my %Closest;

# blast against collection1
my $command = "blastn -db $collection1 -query $infile -evalue $eval -perc_identity $perc_identity -outfmt '6 qseqid sseqid length pident evalue score' -out blast.temp";
print ">$command\n";
my $out = system($command);

print "Reading blast output...\n";
open(IN,'blast.temp') or die $!;
while(<IN>){
	chomp;
	next if $_ =~ /$exclude/;
	my($query,$subject,$length,$iden,$eval,$score) = split(/\t/,$_);
	next if exists($Closest{$query});
	next if $query eq $subject;
	next if $length < $minlen;
	$Closest{$query}->{'collection1'} = [$subject,$score];
}
close IN;
unlink 'blast.temp';

#for my $key (keys %Closest){
#	print "$key $Closest{$key}->{collection1}->[0] $Closest{$key}->{collection1}->[1]\n";
#}

# Collection 2
$command = "blastn -db $collection2 -query $infile -evalue $eval -perc_identity $perc_identity -outfmt '6 qseqid sseqid length pident evalue score' -out blast.temp";
print ">$command\n";
$out = system($command);

print "Reading blast output...\n";
open(IN,'blast.temp') or die $!;
while(<IN>){
	chomp;
	next if $_ =~ /$exclude/;
	my($query,$subject,$length,$iden,$eval,$score) = split(/\t/,$_);
	next if exists($Closest{$query}->{'collection2'});
	next if $query eq $subject;
	next if $length < $minlen;
	$Closest{$query}->{'collection2'} = [$subject,$score];
}
close IN;
unlink 'blast.temp';

print "Writting output...\n";
open(OUT,'>',$outfile) or die $!;
for my $key (keys %Closest){
	# Find closest match
	my $best;
	if(!exists($Closest{$key}->{'collection1'})){
		$best = $Closest{$key}->{'collection2'}->[0];
	}elsif(!exists($Closest{$key}->{'collection2'})){
		$best = $Closest{$key}->{'collection1'}->[0];
	}else{
		my %Score = ($Closest{$key}->{'collection1'}->[0] => $Closest{$key}->{'collection1'}->[1],
			$Closest{$key}->{'collection2'}->[0] => $Closest{$key}->{'collection2'}->[1]);

		my @top = sort{$Score{$b} <=> $Score{$a}} keys %Score;
		$best = $top[0];
	}
			

	print OUT "$key\t$Closest{$key}->{collection1}->[0]\t$Closest{$key}->{collection1}->[1]\t";
	print OUT "$key\t$Closest{$key}->{collection2}->[0]\t$Closest{$key}->{collection2}->[1]\t";
	print OUT "$best\n";
}
close OUT;





