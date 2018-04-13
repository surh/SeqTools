#!/usr/bin/env perl
# Takes a fasta file and extract the predicted amplicon(s).
# For the moment the primers have to be hard-coded on the
# script
# Usage:
#	$ linear_amplify.pl infile.fa primer outfile.fa

use strict;
use warnings;
use Bio::SeqIO;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib dirname abs_path $0;
use SeqTools;

# Read parameters and define primers
my ($ref_fasta,$primer,$outfile) = @ARGV;
#my $ref_fasta = '/home/sur/rhizogenomics/data/culture_database/2012-10-29.isolates.fasta';
#my $Fprimer = 'GCAACGAGCGCAACCC';
#my $Fprimer = 'AACGAGCG[\w]AACCC';	# simplified primer
#my $Rprimer = 'G[CT]ACACACCGCCCGT';
#my $Rprimer = 'G[\w]ACACACCGCCCGT';

die "Usage:\n\t\$ linear_amplify.pl <infile.fa> <primer> <outfile.fa>\n" unless -f $ref_fasta;

# Prepare regexp
my $primer_seq = get_primer($primer);
$primer_seq = $primer unless $primer_seq;
my $regexp = "($primer_seq)(\\w+)";
print "REGEXP:\n==$regexp==\n";

# Read file
my $in = Bio::SeqIO->new(-file => $ref_fasta, -format => 'fasta');
open (OUT,">$outfile") or die "Can't create $outfile ($!)";
my $i = 0;
my $j = 0;
while (my $query = $in->next_seq()){
	my ($amplicon);
	my $seq = $query->seq();
	my $id = $query->id();
	#my $rc_seq = reverse($seq);
	#$rc_seq =~ tr/ACGT/TGCA/;
	if ($seq =~ /$regexp/){
		#print "($1)  $2  ($3)\n";
		$amplicon = $2;
		print OUT ">$id\n";
		print OUT "$amplicon\n";
		$i++;
	}
	#next if $i++ > 10;
	#print "$seq\n";
	$j++;
}
close OUT;

print "$i out of $j sequences amplified\n"

