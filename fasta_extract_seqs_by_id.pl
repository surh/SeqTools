#!/usr/bin/env perl

# Copyright (C) 2015, 2016 Sur Herrera Paredes
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>

use strict;
use warnings;
use Bio::SeqIO;
use Getopt::Long;

my ($infile,$names);
my $usage = "Usage:\n\t>fasta_extract_seqs_by_id.pl -i <infile> -o <outfile> -n <namesfile> [-u <filename>]\n";
my $outfile = '';
my $unfound = '';

my $opts = GetOptions("infile|i=s" => \$infile,
			"outfile|o=s" => \$outfile,
			"names|s=s" => \$names,
			"unfound|u=s" => \$unfound);

die $usage unless -f $infile && -f $names;
die $usage if $outfile eq '';

open(NAMES,$names) or die "Can't open $names ($!)";
my %names;
while(<NAMES>){
	chomp;
	$names{$_} = 0;
}
close NAMES;

print scalar (keys %names) . " names read.\n";



my $in = Bio::SeqIO->new(-format => 'fasta', -file => $infile);
open(OUT,'>',$outfile) or die $!;
my $found = 0;
while(my $Seq = $in->next_seq){
	my $id = $Seq->id;
	my $seq = $Seq->seq;

	if(exists($names{$id})){
		print OUT ">$id\n$seq\n";
		$names{$id}++;
		$found++;
	}
}
close OUT;
print "Found $found sequences.\n";

# Print summary of results
my $not_found = 0;

# Print out names of not found sequences
if($unfound ne ''){
	open(UNFOUND,'>',$unfound) or die "Can't create $unfound ($!)";
}
for my $key (keys %names){
	$not_found++ unless $names{$key};
	print UNFOUND "$key\n" if $unfound ne '' && $names{$key} == 0;
}
print "Did not find $not_found sequences.\n";



