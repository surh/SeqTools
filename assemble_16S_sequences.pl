#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

my ($map_file,$outdir) = @ARGV;

my $phred_bin = 'phred';
my $mira_bin = 'mira';

open(MAP,$map_file) or die $!;
my %Master;
while(<MAP>){
	chomp;
	my ($platemap_file,$tracedir,$plate_id) = split(/\t/,$_);

	# Open file with plate map and trace files
	my @tracefiles = get_files($tracedir,"ab1");
	open(my $PLATE,$platemap_file) or die "Can't open $platemap_file ($!)";

	# Create phred output directory
	my $fastadir = "$outdir/$plate_id.phred/";
	#my $qualdir = "$outdir/$plate_id.qual/";
	mkdir $fastadir unless -d $fastadir;
	#mkdir $qualdir unless -d $qualdir;
	
	# Run phred
	my $command = "$phred_bin -id $tracedir -st fasta -qt fasta -sd $fastadir -qd $fastadir";
	my $out = execute($command);
	my @fastafiles = get_files($fastadir,"seq");
	my @qualfiles = get_files($fastadir,"qual");

	### FUNCTION ###
	while(<$PLATE>){
		chomp;
		my ($row,$col,$strain,$primer,$plateid) = split(/\t/,$_);
		my (@file);

		next if $strain eq '' || $strain eq 'ID';
		if(!exists($Master{$strain})){
			$Master{$strain}->{'fasta'} = ();
			$Master{$strain}->{'qual'} = ();
		}
	
		@file = grep{ /dna\d+\-$row$col\-dangl.ab1.seq/ } @fastafiles;
		my $fasta_file = $file[0];

		@file = grep{ /dna\d+\-$row$col\-dangl.ab1.qual/ } @qualfiles;
		my $qual_file = $file[0];
		
		print "\t$strain\t$row$col\t$fasta_file\t$qual_file\n";
		push(@{$Master{$strain}->{'fasta'}},"$fastadir/$fasta_file");
		push(@{$Master{$strain}->{'qual'}},"$fastadir/$qual_file");
	}


	#if($out != 0){
		## ERROR ##
	#}

	#print "@qualfiles" . "\n";
}

my $strain;
my $assembly_data = "$outdir/assembly/";
mkdir $assembly_data unless -d $assembly_data;
for $strain (keys %Master){
	print "Assembling strain $strain...\n";
	my @qualfiles = @{$Master{$strain}->{'qual'}};
	my @fastafiles = @{$Master{$strain}->{'fasta'}};
	#print "@qualfiles" . "\n";
	#print "@fastafiles" . "\n";

	# Prepare data for assembly
	move_and_rename(\@fastafiles,$assembly_data,'.seq','.fasta');
	move_and_rename(\@qualfiles,$assembly_data,'.qual','.fasta.qual');

	#prepare manifest file
	open(MAN,'>',"manifest.txt") or die $!;
	print MAN "project = $strain\n";
	print MAN "job = est,denovo,accurate\n";
	print MAN "parameters = -GENERAL:number_of_threads=2 SANGER_SETTINGS -AS:epoq=no\n";
	print MAN "readgroup = $strain\n";
	print MAN "data = $assembly_data/*.fasta\n";
	print MAN "technology = sanger\n";
	close MAN;

	# run mira
	my $command = "$mira_bin manifest.txt";
	execute($command);

	# cleanup
	unlink "manifest.txt";
	my @oldfiles = get_files($assembly_data,'');
	unlink "$assembly_data/$_" foreach @oldfiles;

	#last;
}


####
sub execute{
	my ($command) = @_;
	print("Executing:\n\t>$command\n");
	my $out = 0;
	$out = system($command);
	print "\tExit status:$out\n";
	return($out)
}

sub get_files{
	my ($dir,$ext) = @_;
	opendir(DIR,$dir) or die $!;
	my @files = grep{/$ext$/ && -f "$dir/$_"} readdir DIR;
	return(@files);
}

sub move_and_rename{
	my ($filenames_ref,$newdir,$oldsuffix,$newsuffix) = @_;
	my ($file,$command);

	for $file (@{$filenames_ref}){
		my ($name,$path,$suffix) = fileparse($file,$oldsuffix);
		$command = "mv $path/$name$suffix $newdir/$name$newsuffix";
		#print "$command\n";
		execute($command);
	}

}
