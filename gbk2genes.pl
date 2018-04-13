#!/usr/bin/env perl


use strict;
use Getopt::Long;
use Pod::Usage;
use File::Basename;

# Define option variables
my $indir = '';
my $aadir = './faa/';
my $ntdir = './fnt/';
my $gb2tab = '/proj/dangl_lab/bin/SeqTools/gb2tab.py';
my $help = '';

my $opts = GetOptions( "indir|i=s" => \$indir,
			"aadir=s" => \$aadir,
			"ntdir=s" => \$ntdir,
			"gb2tab=s" => \$gb2tab,
			"help|h|man|?" => \$help);

# Check validity of input
pod2usage(-verbose => 2, -exitval => 1) if $help;
die "Incorrect system call. Use -h for help\n" unless $indir;
die "Input directory $indir is not a valid directory\n" unless -d $indir;

# Get GenBank filenames
opendir(DIR,$indir) or die "Can't open directory ($indir) ($!)";
my @gbk_files = grep{ -f "$indir/$_"} readdir DIR;
#print "@gbk_files\n";

#open(OUT,"| ls -lh");
#while(<OUT>){
#	print "$_\n";
#}

# Make output directories
mkdir $aadir unless -d $aadir;
mkdir $ntdir unless -d $ntdir;

# Process files
#process_file('genomes/15227.gbk','faa','fna','gb2tab.py');
for my $file (@gbk_files){
	my ($filename, $directories, $suffix) = fileparse($file, qr/\.[^.]*/);	
	#print "filename:$filename=suffix:$suffix\n";
	my $aafile = "$aadir/$filename.faa";
	my $ntfile = "$ntdir/$filename.fnt";
	open(my $outaafh, '>', $aafile) or die "Can't create $aafile ($!)";
	open(my $outntfh, '>', $ntfile) or die "Can't create $ntfile ($!)";
	process_file("$indir/$file",$outaafh,$outntfh,$gb2tab);
}

##############SUBROUTINES#####################
sub process_file{
	my ($infile,$outaafh,$outntfh,$bin) = @_;
	my $command = "$bin -f CDS -s --locustag --entryname --verbose $infile |";
	#my $i = 0;
	print STDERR "Processing $infile...\n";
	open(my $tab,$command) or die "Can't execute $command";
	while(<$tab>){
		chomp;
		my ($name,$seqnt,$ann,$com) = split(/\t/,$_);

		# Extract aa seq
		my $seqaa = '';
		if($com =~ /\/translation=\"(\w+)\"/){
			$seqaa = $1;

		}

		# Extract locustag
		my $locustag = '';
		if($com =~ /\/locus_tag=\"(\w+)\"/){
			$locustag = $1;
		}else{
			die "$name does not have a locus_tag";
		}

		print $outntfh ">$locustag\n$seqnt\n";
		print $outaafh ">$locustag\n$seqaa\n";
		#print "$_\n";
		#print "============\n";
		#last if $i++ > 10;
	}
}


__END__

=head1 NAME

gbk2genes.pl - Process a directory of GenBank genome files and extract CDSs.

=head1 SYNOPSIS

Uses the CBS feature extraction tool (gb2tab.py) to extract coding sequences (CDSs) and generates
fasta files with both the aminoacid and nucleotide sequences.

=head1 USAGE

$ gbk2genes.pl --indir I<<input_directory>> --aadir I<<aa_output_directory>> --ntdir I<<nt_output_directory>>

=head1 OPTIONS

=over 8

=item --aadir [REQUIRED]

Directory where the output aminoacid fasta files will be created.

DEFAULT='./faa/'

=item --gb2tab

Full path to gb2tab.py executable.

Default='/proj/dangl_lab/bin/SeqTools/gb2tab.py'

=item --indir,i [REQUIRED]

Directory containing only GenBank genome files, to be processed.

=item --ntdir [REQUIRED]

Directory where the output aminoacid fasta files will be created.

DEFAULT='./fnt/'

=item --help, -h, -man, -?

Print help.

=back

=head1 DESCRIPTION

=head1 AUTHOR

Sur from Dangl Lab

=cut


