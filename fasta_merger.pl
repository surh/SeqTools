#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;
use File::Temp;

my ($seq1_file,$seq2_file,$help);
my $reverse1 = '';
my $reverse2 = '';
my $outdir = "./";

my $opts = GetOptions("seq1=s" => \$seq1_file,
			"seq2=s" => \$seq2_file,
			"outdir|o=s" => \$outdir,
			"reverse1" => \$reverse1,
			"reverse2" => \$reverse2,
			"help|h|?|man" => \$help);

my $usage_msg = "Usage:\n\t\$ fasta_merger -seq1 <file1.fa> -seq2 <file2.fa> -outdir <out>\n";
$usage_msg .= "Options:\n\t-reverse1,-reverse2\n\tFlags indicating whether to reverse complemente one of the sequences.\n";
die $usage_msg if $help;
die "Can't find $seq1_file\n" unless -f $seq1_file;
die "Can't find $seq2_file\n" unless -f $seq2_file;

my $in1 = Bio::SeqIO->new(-format => 'Fasta', -file => $seq1_file);
my $in2 = Bio::SeqIO->new(-format => 'Fasta', -file => $seq2_file);

mkdir $outdir;
my $dir = File::Temp->newdir('inputsXXXXX',DIR => $outdir);
my $dirname = $dir->dirname;
my $outputs = File::Temp->newdir('outputsXXXXX',DIR => $outdir,CLEANUP => 0);
my $outputsdir = $outputs->dirname;
while(my $Seq1 = $in1->next_seq){
	die "Number of sequences does not match between files\n" unless my $Seq2 = $in2->next_seq;
	# Gather info
	my $id1 = $Seq1->id;
	my $id2 = $Seq2->id;
	my $seq1 = $Seq1->seq;
	my $seq2 = $Seq2->seq;

	# Create files for EMBOSS merger
	my $file1 = "$dirname/asequence_$id1.fa";
	my $file2 = "$dirname/bsequence_$id2.fa";
	create_single_fasta($file1,$id1,\$seq1);
	create_single_fasta($file2,$id2,\$seq2);

	# Call emboss
	$reverse1 = '-sreverse1' if $reverse1;
	$reverse2 = '-sreverse2' if $reverse2;
	my $outfile = "$outputsdir/$id1.$id2.aln";
	my $outseq = "$outputsdir/$id1.$id2.fa";
	my $command = "merger -asequence $file1 -bsequence $file2 -outfile $outfile -outseq $outseq $reverse2 $reverse1";
	system($command);
}

# Concatenate resutls
my $command = "cat $outputsdir/*.fa > $outdir/merged.fa";
system($command);

##### SUBROUTINES #########
sub create_single_fasta{
	my ($file,$id,$seq_ref) = @_;
	open(FA,'>',$file) or die "Can't create $file ($!)";
	print FA ">$id\n$$seq_ref\n";
	close(FA);
	return;
}




