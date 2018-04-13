#!/usr/bin/env perl
# Takes a fasta file and extract the predicted amplicon(s).
# For the moment the primers have to be hard-coded on the
# script
# Usage:
#	$ amplify.pl -r ref.fa -o outfile.fa -F Fprimer -R Rprimer

use strict;
use Bio::SeqIO;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path $0;
use SeqTools;

# Read parameters and define primers
my ($ref_fasta,$outfile,$Fprimer,$Rprimer) = '';
my $keep_primers = 0;
#my $ref_fasta = '/home/sur/rhizogenomics/data/culture_database/2012-10-29.isolates.fasta';
#my $Fprimer = 'GCAACGAGCGCAACCC';
#my $Rprimer = 'G[CT]ACACACCGCCCGT';
#my $Rprimer = 'G[\w]ACACACCGCCCGT';

my $opts = GetOptions("ref|r|i=s" => \$ref_fasta,
			"outfile|o=s" => \$outfile,
			"Fprimer|F=s" => \$Fprimer,
			"Rprimer|R=s" => \$Rprimer,
			"keep|k" => \$keep_primers);

#print "$ref_fasta\n";
#print "$outfile\n";
#print "$Fprimer\n";
#print "$Rprimer\n";
die "Usage:\tamplify.pl -r ref.fa -o outfile.fa -F Fprimer -R Rprimer [-k]\n" unless (-f $ref_fasta && $Rprimer && $Fprimer && $outfile);


	# Prepare primers
	my $Fprimer_seq = get_primer($Fprimer);
	my $Rprimer_seq = get_primer($Rprimer);
	$Fprimer_seq = $Fprimer unless $Fprimer_seq;
	$Rprimer_seq = $Rprimer unless $Rprimer_seq;
	$Rprimer_seq = reverse_complement($Rprimer_seq);
	my $regexp = "($Fprimer_seq)(\\w+)($Rprimer_seq)";
	print "REGEXP:\n==$regexp==\n";

# Read file
my $in = Bio::SeqIO->new(-file => $ref_fasta, -format => 'fasta');
open (OUT,">$outfile") or die "Can't create $outfile ($!)";
my $match = 0;
my $count = 0;
while (my $query = $in->next_seq()){
	my ($amplicon);
	# Read sequence
	my $seq = $query->seq();
	my $id = $query->id();

	if ($seq =~ /$regexp/i){
		#print "($1)  $2  ($3)\n";
		$amplicon = $2;
		if($keep_primers){
			$amplicon = "$1$amplicon$3";
		}
		print OUT ">$id\n";
		print OUT "$amplicon\n";
		$match++;
	}
	#next if $i++ > 10;
	#print "$seq\n";
	$count++;
}
close OUT;

print "$match out of $count sequences amplified\n";


##SUBROUTINES

