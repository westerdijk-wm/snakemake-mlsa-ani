IFS='' read -r -d '' perl_script <<"EOF"
#!/usr/bin/env perl
use warnings;
use strict;

use biointsam;

### Description ################################################################
# This script to realign hits in SAM files using MUSCLE to identify complete
# homolog region if possible. Requires three inputs:
#  - SAM file with hits
#  - reference FASTA file
#  - query FASTA file
################################################################################

# Try to load all the required modules and die with a useful error message if it fails
BEGIN {
    my @modules = (
	'Bio::Tools::Run::Alignment::Muscle',
	'Bio::SimpleAlign',
	'Bio::Seq',
	'Bio::SeqIO',
	'List::Util qw[min max]',
	'Data::Dumper',
	);
    # string to store the missing modules for printing
    my $missing;
    for (@modules) {
	eval "use $_";
	if($@) {
	    $missing .= "\t'$_'\n";
	}
    }
    if ($missing) {
	# Tell the user which modules are missing
	die "ERROR: The following modules need to be installed first:\n$missing";
    }
}

# Collect metadata as arguments
my ($sam, $ref, $query) = @ARGV;

open(my $samfh, '<', $sam) || die $!;

my %ref;
while(<$samfh>) {
    #print "$_";
    my %hit;
    biointsam::parse_sam($_, \%ref, \%hit);
    # Header lines contain no hits
    unless (%hit) {
	# Print header to maintain a valid SAM output
	print "$_\n";
	next;
    }
    # Nothing to do if there is no hit for the query sequence, so skip it
    next if $hit{'RNAME'} eq "*";
    #print biointsam::sam_string(\%hit), "\n";
    &realign(\%hit, $ref, $query);
    print biointsam::sam_string(\%hit), "\n";
}

sub cigar_update {
    # Update cigar whether type is switched
    # Increment alignment by one
    #  - type: the current CIGAR tag M, I, D, etc.
    #  - len: length of the current elemnet (e.g. 5 in 5M)
    #  - new: the CIGAR tag of the current nucleotide
    #  - cigar: the CIGAR string so far
    my ($type, $len, $new, $cigar) = @_;
    if ($$type && $$type eq $new) {
	$$len++;
    } else {
	$$cigar .= $$len . $$type if $$type;
	$$type = $new;
	$$len = 1;
    }
}
sub aln2cigar {
    # Takes two sequences that are aligned and returns the CIGAR and edit distance
    my ($seq1, $seq2) = @_;
    my $total = length $seq1;
    die "ERROR: sequences have different lengths\n" unless $total == length($seq2);
    my $edit = 0;
    my $type;
    my $len;
    my $cigar = "";
    # Loop through each position in the alignment
    for my $p (1..$total) {
	my $base1 = substr($seq1, $p - 1, 1);
	my $base2 = substr($seq2, $p - 1, 1);
	if ($base1 eq $base2) {
	    next if $base1 eq '-';
	    # Match (M)
	    &cigar_update(\$type, \$len, "M", \$cigar);
	    next; # skip adding an edit distance
	} elsif ($base1 eq "-") {
	    # Insertion (I)
	    &cigar_update(\$type, \$len, "I", \$cigar);
	} elsif ($base2 eq "-") {
	    # Deletion (D)
	    &cigar_update(\$type, \$len, "D", \$cigar);
	} else {
	    # Mismatch (M)
	    &cigar_update(\$type, \$len, "M", \$cigar);
	}
	$edit++;
    }
    # Update the final stretch
    &cigar_update(\$type, \$len, "", \$cigar);
    return $cigar, $edit;
}

sub realign {
    # Uses MUSCLE to realign the refernce and the query sequence by
    # clipping the surrounding of the hit to get so complete possible
    # homolog region from the query, then updates the %hit
    # INPUT:
    #  1. hash reference for the SAM %hit
    #  2. Refernce sequence file name
    #  3. Query sequence file name
    my ($hashref, $ref, $query) = @_;
    my %hit = %$hashref;
    my $hitaln = biointsam::parse_cigar($hit{'CIGAR'}, $hit{'FLAG'}, $hit{'SEQ'});
    my $rev;
    $rev++ if $hit{'FLAG'} & 16;
    
    # Get the sequence of R and Q
    my $rio = Bio::SeqIO->new(-file=>$ref,-format=>'fasta');
    my $rseq;
    while ($rseq = $rio->next_seq()) {
	last if $rseq->primary_id() eq $hit{'RNAME'};
    }
    my $qio = Bio::SeqIO->new(-file=>$query,-format=>'fasta');
    my $qseq;
    while ($qseq = $qio->next_seq()) {
	last if $qseq->primary_id() eq $hit{'QNAME'};
    }

    # Get and calculate useful variables
    my $rlen = $rseq->length();
    # Start position + ref alignment length - 1 
    my $rend = $hit{'POS'} + $hitaln->{'length'} - $hitaln->{'insertion'} - 1;
    my $qlen = $hitaln->{'length'} - $hitaln->{'deletion'} + $hitaln->{'unmapped'};
    my $qend = $qlen - $hitaln->{'unmapped'} + $hitaln->{'start'} - 1;

    # How much is missing from the reference
    my $missing5 = $hit{'POS'} - 1;
    my $missing3 = $rlen - $rend;
    # Need to reverse for reverse alignments
    ($missing5, $missing3) = ($missing3, $missing5) if $rev;
    
    # Extract target region
    # Calculate desired region to extract from Q
    # begin = max { 1,
    #               Q alignment start - missing from ref - 100 }
    my $begin = max(1, ($hitaln->{'start'} - ($missing5) - 100) );
    my $end = min($qlen, ($qend + ($missing3) + 100) );
    # Get the sequence
    my $bit = $qseq->subseq( $begin, $end );
    $qseq->seq($bit);
    # Reverse sequence if it matched the reverse
    $qseq = $qseq->revcom() if $rev;

    # Check if R is much larger than Q
    #  How much is not aligned from Q?
    my $extra5 = $hitaln->{'start'} - 1;
    my $extra3 = $qlen - $qend;
    #  Adjsut the length of R sequences by clipping from the ends as needed
    my $adj5 = 0;
    my $adj3 = 0;
    if ($missing5 - 100 > $extra5) {
	$adj5 = $missing5 - 100 - $extra5;
	# print STDERR "A lot more is missing from R ($missing5) than what is in Q ($extra5)\n";
    }
    if ($missing3 - 100 > $extra3) {
	$adj3 = $missing3 - 100 - $extra3;
	# print STDERR "A lot more is missing from R ($missing3) than what is in Q ($extra3)\n";
    }
    # Reverse for reverse alignment
    ($adj5, $adj3) = ($adj3, $adj5) if $rev;
    #my $get = $rlen - ($adj5 + $adj3);
    #print STDERR "susbtring $adj5, $rlen - ($adj5 + $adj3) => $get " . length($rseq->seq()) . "\n";
    $rseq->seq(substr($rseq->seq(), $adj5, $rlen - ($adj5 + $adj3)));
    
    ## Align sequences
    # Build a muscle alignment factory
    my $factory = Bio::Tools::Run::Alignment::Muscle->new();
    # Hide MUSCLE STDERR text
    $factory->quiet(1);
    my @seq = ($rseq, $qseq);
    my $aln = $factory->align(\@seq);

    
    # Clip gapped regions from begin and end based on the ref
    my $seq = $aln->get_seq_by_id($hit{'RNAME'})->seq();
    $seq =~ /^(-*)/;
    # Start is a 0 based position (handy for substr later)
    my $start = length $1;
    $seq =~ /^(?:-*)(.*?)(?:-*)$/;
    my $matched = length $1;
    my $stop = $start + $matched;
    
    # Get the matched region
    #  for Q
    my $match = substr($aln->get_seq_by_id($hit{'QNAME'})->seq(), $start, $matched);
    #  for R
    my $matched_ref = substr($seq, $start, $matched);

    # Check gapped regions at begin and end of the query
    $match =~ /^(-*)/;
    my $gap5 = length $1;
    $match =~ /(-*)$/;
    my $gap3 = length $1;

    # clip alignment again
    $match = substr($match, $gap5, $matched - ($gap5 + $gap3));
    $matched_ref = substr($matched_ref, $gap5, $matched - ($gap5 + $gap3));

    # Update SAM hit
    my ($cigar, $edit) = &aln2cigar($matched_ref, $match);

    # Remove gaps for SAM SEQ column
    $match =~ s/-//g;

    # Calculate aligned region of the Q
    #  begin and end are the start and end position of the region used for the alignment
    #  start and stop are the start and end position that are used from the alignment
    #  (start is zero based, while begin is 1 based)
    my $x = $begin + $start;
    my $mlen = length $match;
    my $y = $x + $mlen - 1;
    if ($rev) {
	$y = $end - $start;
	$x = $y + 1 - $mlen;
    }

    # Calculate query clipping values for CIGAR
    # query start and end postions are $x and $y
    my $clip1 = $x - 1;
    my $clip2 = $qlen - $y;
    if ($rev) {
	($clip1, $clip2) = ($clip2, $clip1);
    }	 
    if ($clip1) {
	$cigar = $clip1 . "H" . $cigar;
    }
    if ($clip2) {
	$cigar .= $clip2 . "H";
    }

    
    biointsam::score($hashref);
    my $old = $hashref->{'AS:i'};

    # Update hit
    $hashref->{'POS'} = $adj5 + $gap5 + 1; # adj5 (not used from the R) + gap5 ("delition" in the Q)
    $hashref->{'SEQ'} = $match;
    $hashref->{'NM:i'} = $edit;
    $hashref->{'CIGAR'} = $cigar;

    # Adding the similarty score to SAM or the old score?

    
    # Update score
    biointsam::score($hashref);
    my $new = $hashref->{'AS:i'};
    
    # Compare scores?
    #  $old: Old score
    #  $new: New score (after MUSCLE)
    #  What would be the score if we just pasted the missing bits without MUSCLE or doing a new MUSCLE with less slack (default is 100)?
    
}

sub get_similarity {
    my ($seq1, $seq2) = @_;
    my $length = length $seq1;
    unless ($length == length $seq2) {
	print STDERR "ERROR: Sequences have a different length for similarity calculation\n\t$seq1\n\t$seq2\n";
    }
    my $same = 0;
    while ($seq1) {
	my $b1 = substr($seq1, 0, 1, '');
	my $b2 = substr($seq2, 0, 1, '');
	$same++ if $b1 eq $b2;
    }
    return $same / $length; 
}
EOF

# Create temp perl file
cmd_file="${snakemake[rule]}_${snakemake_wildcards[sample]}.pl"
printf '%s\n' "$perl_script" > "$cmd_file"

# Execute
perl "$cmd_file" \
    "${snakemake_input[0]}" \
    "${snakemake_input[1]}" \
    "${snakemake_input[2]}" \
    > "${snakemake_output[0]}" \
    2>> "${snakemake_log[0]}"

status=$?

rm -f "$cmd_file"

exit $status