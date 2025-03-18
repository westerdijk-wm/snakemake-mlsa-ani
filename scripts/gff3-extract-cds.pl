#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;                     # locate this script
use lib "$FindBin::RealBin/lib";  # use the parent directory

use bioint::gff3;

#use Data::Dumper;

#===DESCRIPTION=================================================================
my $description = "Description:\n\tA tool to extract CDS sequences based on a GFF3 file.\n" .
    "\tIf CDS is a single line with introns, then intronic sequences are printed in lowercase.\n";
my $usage = "Usage:\n\t$0 [-h | --help] <GFF3 file> <FASTA file>\n";
my $options = 
    "Options:\n" .
    "\t-h | --help\n\t\tPrint the help message; ignore other arguments.\n" .
    "\n";

#===MAIN========================================================================

&print_help(@ARGV);

# Hash to store the sequences: key (id and defintion) and value (sequence) 
my %fas_data;
# Array to store the order of the sequences
my @ids;

my ($hitfile, $fastafile) = @ARGV;

# Could use Bio::SeqIO instead
&read_fasta(\%fas_data, \@ids, $fastafile);

my @order;
my %collection;
$hitfile = undef if $hitfile && $hitfile eq '-';
my $in;
if ($hitfile) {
	open $in, '<', $hitfile || die $!;
} else {
	$in = *STDIN;
}
#open (my $in, "<", $hitfile) || die $!;
while (<$in>) {
    s/\R//g;
#    push @hits, $_;
# }

# for my $h (@hits) {
    # h short for hit
    my $h = $_;
    my %gff;
    bioint::gff3::parse_gff($h, \%gff);
    next unless $gff{'type'} eq "CDS";
    # Get "contig" sequence
    my $seq = $fas_data{ $gff{'seqid'} };
    # Get region seq
    my $cds = substr($seq, $gff{'start'} - 1, $gff{'end'} - $gff{'start'} + 1);

    $cds = &reverse_seq($cds) if $gff{'strand'} eq '-';

    if ($gff{'Gap'}) {
	    $cds = &lc_intron_gap($cds, $gff{'Gap'});
    }
    my @cols = split/\t/, bioint::gff3::gff_string(\%gff);
    my $idline = $gff{'ID'} . "\t" . $cols[8];
    if ($gff{'ID'}) {
	    # it may be a multi line CDS
	    if ($collection{ $idline }) {
	        $collection{ $idline } .= $cds;
	    } else {
	        $collection{ $idline } = $cds;
	        push @order, $idline;
	    }
    } else {
	    # Single line entry, print as it is

	    print &to_fasta($gff{'seqid'} . ":" . bioint::gff3::get_pos(\%gff). "\t" . $_, $cds);
    }
}

for (@order) {
    print &to_fasta($_, $collection{$_});
}


#===SUBROUTINES=================================================================

sub find_stop {
    # Extend the reading frame untill a stop codon is found
    
}


sub gap_string {
    # return the GFF3 Gap string for the ORF based on the case of the nucleotides
    my ($seq) = @_;
    $_ = $seq;
    my @gap;
    while ($_) {
	s/^(([a-z]+)|([A-Z]+))//;
	my $chunk = $1;
	my $type = "M";
	if ($chunk =~ /[a-z]/) {
	    $type = "D";
	}
	push @gap, $type . length($chunk);
    }
    return "@gap";
}

sub lc_intron {
    # Make intron bases lowercase based on the vulgar string of exonerate
    my ($seq, $vulgar) = @_;
    my $new;
    while ($vulgar =~ /(\S+)\s+(\d+)\s+(\d+)/g) {
	my ($type, $q, $t) = ($1, $2, $3);
	next unless $t > 0;
	my $chunk = substr($seq, 0, $t, "");
	$chunk = lc($chunk) if ($type eq "5" || $type eq "I" || $type eq "3");
	$new .= $chunk;
    }
    return $new;
}

sub lc_intron_gap {
    # Make intron bases lowercase based on the vulgar string of exonerate
    my ($seq, $gap) = @_;
    my $new;
    for (split/ /, $gap){ #while ($gap =~ /(\S+)(\d+)/g) {
	my $type = substr($_, 0, 1, "");
	my $len = $_;
	next unless $len > 0;
	my $chunk = substr($seq, 0, $len, "");
	$chunk = lc($chunk) if $type eq "D";
	$new .= $chunk;
    }
    return $new;
}

sub check_internal_stop {
    my ($seq) = @_;
    my $prot = &translate($seq);
    # Remove STOP codon from the end if it is present
    $prot =~ s/\*$//;
    if ($prot =~ /^([^\*]*)\*/) {
	# return the position of the first STOP codon
	return length($1) + 1;
    }
    # If non encountered, then it returns undefind == FALSE
}

sub check_signal {
    # Check the encoded sequnece for a signal peptide
    # Returns the length of the signal peptide and the individual sub regions
    my ($seq) = @_;
    my $prot = &translate($seq);
    $prot =~ s/\*//g;
    my ($signal, $n, $h, $c) = (0, 0, 0, 0);
    if ($prot) {
	open(my $pipe, "perl -e 'print \">orf\n$prot\n\"' | phobius 2>/dev/null |") || die $!;
	# FT   SIGNAL        1     21
	# FT   REGION        1      6       N-REGION.
	# FT   REGION        7     17       H-REGION.
	# FT   REGION       18     21       C-REGION.
	# FT   TOPO_DOM     22    271       NON CYTOPLASMIC.
	for(<$pipe>) {
	    if (/FT\s+SIGNAL\s+(\d+)\s+(\d+)/) {
		$signal = $2 - $1 + 1;
	    } elsif (/FT\s+REGION\s+(\d+)\s+(\d+)\s+(\S+)/) {
		my $type = $3;
		my $len = $2 - $1 + 1;
		$n = $len if ($type eq "N-REGION.");
		$h = $len if ($type eq "H-REGION.");
		$c = $len if ($type eq "C-REGION.");
	    }
	}
	close $pipe;
    }
    return ($signal, $n, $h, $c);
}

sub print_help {
    # Print out the usage to STDERR
    # Takes in the @ARGV as input
    my @args = @_;
    for (@args) {
	if (/-?-h(elp)?/) {
	    die "$usage\n$description\n$options";
	}
    }
}

sub read_fasta {
    # Convert FASTA string into a hash with IDs for keys and sequences
    #  as values and stores the original order in an array
    # This subroutine requires three arguments:
	#	1) filehandle for the FASTA file
	#	2) a hash reference to store the sequences in
	#	3) an array reference to store the IDs in the same
	#          order as the original file 
    # If an ID line is present multiple times then a warning is printed
    #  to STDERR
    my ($hash, $list, $file) = @_;
    # Use STDIN if file is '-'
    $file = undef if $file && $file eq '-';
    my $in;
    if ($file && -e $file) {
	open $in, '<', $file || die $!;
    } else {
	$in = *STDIN;
    }
    # Store the sequence id
    my $seq_id;
    for (<$in>) {
        # Remove line endings
        s/\R//g;
	# Skip empty lines
	next if /^\s*$/;
	# Check wheter it is an id line
	if (/>(\S+)/) {
	    # Save the id and the definition and store it in the array
	    $seq_id = $1;
	    print {*STDERR} "WARNING: <$seq_id> is present in multiple copies\n" if $hash->{$seq_id};
	    push @$list, $seq_id;
	} else {
	    # If there was no id lines before this then throw an error
	    unless (defined $seq_id) {
		print "Format error in FASTA file! Check the file!\n";
		last;
	    }
	    # Remove white space
	    s/\s+//g;
	    # Add to the sequence
	    $hash->{$seq_id} .= $_;
	}
    }
    close $in;
}

sub to_fasta {
    # Return a fasta formated string
    my ($seq_name, $seq, $len) = @_;
    # default to 60 characters of sequence per line
    $len = 60 unless $len;
    # Print ID line
    my $formatted_seq = ">$seq_name\n";
    # Add sequence lines with $len length
    while (my $chunk = substr($seq, 0, $len, "")) {
	$formatted_seq .= "$chunk\n";
    }
    return $formatted_seq;
}

sub print_fasta {
    # Print all the sequences to STDOUT in FASTA format
    my ($hash, $list) = @_;
    for (@$list) {
	print &to_fasta($_, $hash->{$_});
    }
}

sub reverse_seq {
    # Reverse complements the sequences
    my ($seq) = @_;
    # Reverse the sequnce
    my $complement = reverse $seq;
    # Complement the sequence
    $complement =~ tr/ACGTacgtWwMmRrSsKkYyBbVvDdHh/TGCAtgcaWwKkYySsMmRrVvBbHhDd/;
    return $complement;
}


sub reverse_fasta {
    # Reverse complements the sequences for each entry in the hash
    # There is no return for this subroutine
    #   The sequence is manipulated within the hash itself
    my ($hash, $list) = @_;
    for (@$list) {
	$hash->{$_} = &reverse_seq($hash->{$_});
    }
}
