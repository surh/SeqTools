#package SeqTools;
use strict;
use warnings;
#use Exporter

#my @EXPORT = qw / get_primer reverse_complement /;
#my @EXPORT_OK = qw / get_primer reverse_complement /;


sub get_primer{
	my ($primer_id) = @_;
	my $seq;
	if($primer_id eq '515F'){
		$seq = 'GTGCCAGC[CA]GCCGCGGTAA';
	}elsif($primer_id eq '338F'){
		$seq = 'ACTCCTACGGGAGGCAGCA';
	}elsif($primer_id eq '1492R'){
		$seq = 'ACCTTGTTACGACTT';
	}elsif($primer_id eq '806R'){
		$seq = 'GGACTAC[ACT][ACG]GGGT[AT]TCTAAT';
	}elsif($primer_id eq '1392R'){
		$seq = 'ACGGGCGGTGTGT[AG]C';
	}elsif($primer_id eq '804F'){
		$seq = 'ATTAGATACCC[AGT][AG]GTAGT';
	}elsif($primer_id eq '926F'){
		$seq = 'AAACT[CT]AAA[GT]GAATTGACGG';
	}elsif($primer_id eq '1114F'){
		$seq = 'GCAACGAGCGCAACCC';
	}elsif($primer_id eq 'ITS_9'){
		$seq = '[ACGT][ACGT][ACGT][ACGT][ACGT]GAACGCAGC[AG]AA[TAG][TAG]G[CT]GA';
	}elsif($primer_id eq 'ITS_4'){
		$seq = 'TCCTCCGCTTATTGATATGC';	
	}else{
		#die "Primer $primer_id not supported";
		print "Primer ID not found. Assuming primer sequence was given\n";
		$seq = 0;
	}
	return $seq;
}

sub reverse_complement{
	# Reverse complements a DNA sequence.
	my ($seq) = @_;
	my $rc_seq = reverse($seq);
	$rc_seq =~ tr/ACGTacgt][/TGCAtgca[]/;
	return $rc_seq;
}

1;

