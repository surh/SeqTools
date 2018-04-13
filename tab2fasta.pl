#!/usr/bin/env perl
# Perl script that takes a tab delimited file of sequences, and
# converts it to fasta. The tab delimited file should contain two
# columns where the first is the id, and the second is the sequence
# Usage:
#	$ tab2fasta.pl infile outfile

# Load libraries
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

# Define global variables
my ($infile,$outfile,$help) = '';
my $idcol = 1;
my $seqcol = 2;

# read options
my $opts = GetOptions("infile|i=s" => \$infile,
			"outfile|o=s" => \$outfile,
			"idcol=i" => \$idcol,
			"seqcol=i" => \$seqcol,
			"help|h|man" => \$help);

pod2usage(-exitval => 1, -verbose => 2) if $help;
die "Usage:\n\t\$ tab2fasta.pl -infile <infile.tab> -outfile <outfile.fa> [-idcol <colnum> -seqcol <colnum>]\n\t\$ tab2fasta.pl -help\n" unless $infile && $outfile;

print "====================\n";
print "Welcome to tab2fasta.pl\n";


open(TAB,$infile) or die "Can't open $infile ($!)";
open(FA,">$outfile") or die "Can't create $outfile ($!)";
print "Files opened...";
$idcol--;
$seqcol--;
my $count = 0;
while(<TAB>){
	chomp;
	my @line = split(/\t/,$_);
	my ($id,$seq) = ($line[$idcol],$line[$seqcol]);
	print FA ">$id\n";
	print FA "$seq\n";
	$count++;
}
close TAB;
close FA;

print "$count sequences were processed...\n";
print "====================\n";

__END__

=head1 NAME

tab2fasta.pl - convert tab delimited sequence file to fasta format.

=head1 SYNOPSIS

Takes a tab-delimited file and the column numbers for identifiers and sequences, and creates a fasta file with them.

=head1 USAGE

For a file that has ID's on the first column and sequences on the second use:

$ tab2fasta.pl -infile I<<infile.tab>> -outfile I<<outfile.fasta>>

For specifying columns use

$ tab2fasta.pl -infile I<<infile.tab>> -outfile I<<outfile.fasta>> -idcol I<<col_number>> -seqcol I<<col_number>>

For help:

$ tab2fasta.pl -help

=head1 OPTIONS

=over 8

=item -infile, -i [REQUIRED]

Name of the input tab-delimited file.

=item -outfile, -o [REQUIRED]

Name of the fasta file to create.

=item -idcol

Column number where the sequence IDs are stored.

DEFAULT=1

=item -seqcol

Column number where the sequences are stored.

DEFAULT=2

=item -help, -man, -h

Print help

=back

=head1 DESCRIPTION

=head1 AUTHOR

Sur from Dangl Lab

=cut


