#!/usr/bin/env perl
##!/bin/env perl
# Obtains the reverse complement of sequences in a 
# fasta file
# Usage:
#	$ fasta_reverse_complement.pl seqs.fa out.fa

use strict;
use warnings;
use Bio::SeqIO;

# Read arguments
my ($seqs_file,$out_file) = @ARGV;

die "IUPAC compatible reverse complement for DNA sequences.\nUsage:\n\t\$ fasta_reverse_complement.pl <seqs.fa> <out.fa>\n" unless $seqs_file && $out_file;
die "$seqs_file not found ($!)" unless -f $seqs_file;

# Open query sequences file
my $Seqs = Bio::SeqIO->new( -file => "$seqs_file", -format => 'Fasta');

# Open outfile
open(OUT,">$out_file") or die "Can't create $out_file ($!)";

# Search each query sequence
while(my $query = $Seqs->next_seq()){
	# Create a fasat file with current query.
	my $id = $query->id();
	#print OUT "$id\n";
	my $seq = $query->seq();
	my $rc_seq = reverse($seq);
	$rc_seq =~ tr/AaGgCcTtYyRrWwSsKkMmDdVvHhBbNn-/TtCcGgAaRrYyWwSsMmKkHhBbDdVvNn-/;
	print OUT ">$id\n$rc_seq\n";
}
close OUT;

