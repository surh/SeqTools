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

my $input = '';
my $map = '';
my $groupcol = 0;
my $idcol = 1;
my $skip = 1;
my $outdir = '';
my $id_split_char = '_';
my $help = '';

my $usage = "\$ split_reads_from_samples.pl -input <input.fasta> -outdir <outdir> -map <map.txt> -groupcol <colnum> -idcol <colnum>\n";

my $opts = GetOptions("input=s" => \$input,
			"map=s" => \$map,
			"outdir=s" => \$outdir,
			"groupcol=i" => \$groupcol,
			"idcol=i" => \$idcol,
			"help|man|?|h" => \$help);

die "1:\n$usage" unless -f $input;
die "2:\n$usage" unless -f $map;
die "3:\n$usage" unless $groupcol > 0;
die "4:\n$usage" unless $outdir ne '';

# Making sure iutput directory is there
(mkdir $outdir or die "Can't create $outdir ($!)") unless -d $outdir;

# run pipeline
my ($map_ref, $group_ref) = map_groups($map,$groupcol,$idcol,$skip);
my ($outfiles_ref) = create_output_files($outdir,$group_ref);
split_reads($input,$id_split_char,$outfiles_ref,$map_ref);

##### SUBROUTINES ###
sub map_groups{
	my ($map,$groupcol,$idcol,$skip) = @_;
	open(MAP,$map) or die "Can't open $map ($!)";
	$groupcol--;
	$idcol--;
	my $i = 0;
	my (@line,$id,$group,%Table,%Group);
	print "Reading $map to get groups per sample...\n";
	while(<MAP>){
		chomp;
		next if $i++ < $skip;
		@line = split(/\t/,$_);
		$id = $line[$idcol];
		$group = $line[$groupcol];
		#print "\t==$id,$group==\n";
		$Table{$id} = $group;
		$Group{$group} = 1;	# May add a counter for double checking numbers at the end
	}
	close MAP;
	return(\%Table,\%Group);
}

sub create_output_files{
	my ($outdir,$group_ref) = @_;
	my @groups = keys %{$group_ref};
	my ($group,%outfiles);
	print "Creating output files per group...\n";
	for $group (@groups){
		$outfiles{$group} = Bio::SeqIO->new(-file => ">$outdir/$group.fasta", -format => 'fasta') or die "($!)";
	}

	return(\%outfiles);
}

sub split_reads{
	my ($infile, $id_split_char, $outfiles_ref, $map_ref) = @_;
	my $in = Bio::SeqIO->new(-file => $infile, -format => 'fasta') or die "($!)";
	my $seq;
	print "Splitting sequences...\n";
	my $nseqs = 0;
	my $nsplit = 0;
	while($seq = $in->next_seq){
		my $id = $seq->id;

		my ($sample,@trash) = split(/$id_split_char/, $id);

		if(exists($map_ref->{$sample})){
			my $group = $map_ref->{$sample};
			$outfiles_ref->{$group}->write_seq($seq);
			#print "\t==$id\t$sample\t$group\n";
			$nsplit++;
		}
		$nseqs++;
	}

	print "\tProcessed $nseqs sequences.\n\tSplit $nsplit sequences.\n";
}

