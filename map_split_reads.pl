#!/usr/bin/env perl

#    (C) Copyright 2017 Sur Herrera Paredes
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

use warnings;
use strict;
use Bio::SeqIO;
use Getopt::Long;
use File::Basename;

my $indir = '';
my $outdir = '';
my $ref = '';
my $strainmap = '';
my $mapid = 0.985;
my $strainidcol = 1;
my $straingroupcol = 4;
my $usearch = '/proj/dangl_lab/bin/makeOTUs/usearch7.0.1090_i86linux64';
my $uc2tab = '/proj/dangl_lab/bin/makeOTUs/make_otu_table.pl';
my $tax = '/proj/dangl_lab/data/syncom_refs/ref_wheel/taxonomy.txt';

my $opts = GetOptions("indir=s" => \$indir,
			"outdir=s" => \$outdir,
			"ref=s" => \$ref,
			"strainmap=s" => \$strainmap,
			"mapid=f" => \$mapid);

die "1:\n" unless -d $indir;
die "2\n" unless $outdir ne '';
die "3:\n" unless -f $ref;
die "4:\n" unless -f $strainmap;
die "5:\n" unless $mapid >= 0 && $mapid <= 1;


(mkdir $outdir or die "Can't create $outdir ($!)") unless -d $outdir;

# Run pipeline
my $groups_ref = get_strain_groups($strainmap, $strainidcol, $straingroupcol);
my $seqs_ref = get_strain_sequences($ref);
map_file_by_file($indir,$outdir,$groups_ref,$seqs_ref,$mapid,$usearch,$uc2tab,$tax);

# Subroutines
sub get_strain_groups{
	my ($strainmap, $strainidcol, $straingroupcol) = @_;
	open(MAP,$strainmap) or die "Can't open $strainmap ($!)";
	print "Reading strain group assignments...\n";
	$strainidcol--;
	$straingroupcol--;
	my (@line,%groups);
	while(<MAP>){
		chomp;
		@line = split(/\t/,$_);
		my $strain = $line[$strainidcol];
		my $group = $line[$straingroupcol];
		#print "\t==$strain\t$group\n";
		if(exists($groups{$group})){
			push(@{$groups{$group}}, $strain);
		}else{
			$groups{$group} = [$strain]; 
		}
	}
	close MAP;

	#for (keys %groups){
	#	my @temp = @{$groups{$_}};
	#	print "$_\t" . "@temp" . "\n";
	#}

	return(\%groups)
}

sub get_strain_sequences{
	my ($ref) = @_;
	my $in = Bio::SeqIO->new(-file => $ref, -format => 'fasta');
	my ($seq,%SEQS);
	print "Reading reference sequences...\n";
	while($seq = $in->next_seq){
		my $id = $seq->id;
		$SEQS{$id} = $seq;
	}

	return(\%SEQS);
}

sub map_file_by_file{
	my ($indir,$outdir,$groups_ref,$seqs_ref,$mapid,$usearch,$uc2tab,$tax) = @_;
	opendir(DIR, $indir) or die "Can't open $indir ($!)";
	my @files = grep{/\.fasta$/ && -f "$indir/$_"} readdir DIR;
	close DIR;

	print "Build references and map reads...\n";
	my ($file,$cmd,$out);
	for $file (@files){
		my $group_name = basename($file,'.fasta');
		next if $group_name eq 'No Bacteria';
		next unless -s "$indir/$file" > 0;

		print "\tCreating reference for $group_name...\n";
		my $groupdir = "$outdir/$group_name";
		mkdir "$groupdir" or die "Can't create $groupdir ($!)";
		my $ref_file = create_group_reference($group_name,$groups_ref, $seqs_ref,$groupdir);

		print "\tMapping reads of $file...\n";
		$cmd = "$usearch -usearch_global $indir/$file -db $ref_file -id $mapid -strand plus -uc $groupdir/ref_table.uc -maxaccepts 0 -maxrejects 0 -threads 1";
		$out = execute($cmd);

		print "\tCreating table...\n";
		$cmd = "$uc2tab -i $groupdir/ref_table.uc -o $groupdir -t $tax";
		$out = execute($cmd);
	}

}

sub create_group_reference{
	my ($group_name, $groups_ref, $seqs_ref, $outdir) = @_;

	my $outfile = "$outdir/ref.fa";
	my $block1 = substr($group_name,0,2);
	my $block2 = substr($group_name,2,2);
	#print "$block1,$block2==\n";

	# Add sequences from blocks
	my $out = Bio::SeqIO->new(-format => 'fasta', -file => ">$outfile") or die "$!";
	add_block_seqs($block1,$groups_ref,$seqs_ref,$out);
	add_block_seqs($block2,$groups_ref,$seqs_ref,$out);
	add_block_seqs('contaminant',$groups_ref,$seqs_ref,$out);

	return($outfile);
}

sub add_block_seqs{
	my ($block, $groups_ref, $seqs_ref, $out) = @_;
	
	my ($strain, $seq);
	for $strain (@{$groups_ref->{$block}}){
		$seq = $seqs_ref->{$strain};
		$out->write_seq($seq);
	}
}

sub execute{
	my ($command) = @_;
	print STDERR "Executing:\n\t>$command\n";
	my $out = system($command);
	print STDERR "Exit status: $out\n";
	die "Command failed ($command) ($!)" if $out;
	return $out;
}

