#!/usr/bin/env perl
#	$ gbk2fasta.pl -i infile -o outfile

use warnings;
use strict;
use Bio::SeqIO;
use Pod::Usage;
use Getopt::Long;

my ($gbk,$fasta,$help);

my $opts = GetOptions("input|i=s" => \$gbk,
			"output|o=s" => \$fasta,
			"help|man" => \$help);

pod2usage(-exitval => 1, -verbose => 2) if $help || !$gbk || !$fasta;


my $in = Bio::SeqIO->new(-format => 'genbank',-file => $gbk);
open(OUT,">$fasta") or die "Can't create $gbk file ($!)";
my $count = 0; 
while(my $seq = $in->next_seq()){
	my $id = $seq->id;
	my $sequence = $seq->seq;
	print OUT ">$id\n$sequence\n";
	print "Wrote $id...\n";
	$count++;
}
close OUT;
print "Read and wrote $count sequences.\n";

__END__

=head1 USAGE

gbk2fasta -i I<<input_genbank_file>> -o I<<output_fasta_file>>

=cut

