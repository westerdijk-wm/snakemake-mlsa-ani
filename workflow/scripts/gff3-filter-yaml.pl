#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;                     # locate this script
use lib "$FindBin::RealBin/lib";  # use the parent directory

use bioint::gff3;

use YAML qw(LoadFile);

#use Data::Dumper;

#===DESCRIPTION=================================================================
my $description = "Description:\n\tA tool to filter features based on YAML specifications.\n";
my $usage = "Usage:\n\t$0 [-h | --help] <GFF3 file> <YAML file>\n";
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

my ($hitfile, $yamlfile) = @ARGV;

my %genes;
# Read YAML
my $yamldata = LoadFile($yamlfile);

if ($yamldata->{'genes'}) {
    for (@{ $yamldata->{'genes'} }) {
        $genes{$_}++;
    }
}

my @order;
my %collection;
open (my $in, "<", $hitfile) || die $!;
while (<$in>) {
    s/\R//g;
    my $h = $_;
    my %gff;
    bioint::gff3::parse_gff($h, \%gff);
    my $keep = undef;
    if ($gff{'gene'} && $genes{ $gff{'gene'} }) {
        print bioint::gff3::gff_string(\%gff) . "\n";
    }
    # next unless $gff{'type'} eq "CDS";
    # # Get "contig" sequence
    # my $seq = $fas_data{ $gff{'seqid'} };
    # # Get region seq
    # my $cds = substr($seq, $gff{'start'} - 1, $gff{'end'} - $gff{'start'} + 1);

    # $cds = &reverse_seq($cds) if $gff{'strand'} eq '-';

    # if ($gff{'Gap'}) {
	# $cds = &lc_intron_gap($cds, $gff{'Gap'});
    # }
    # if ($gff{'ID'}) {
	# # it may be a multi line CDS
	# if ($collection{ $gff{'ID'} }) {
	#     $collection{ $gff{'ID'} } .= $cds;
	# } else {
	#     $collection{ $gff{'ID'} } = $cds;
	#     push @order, $gff{'ID'};
	# }
    # } else {
	# # Single line entry, print as it is
	# print &to_fasta($gff{'seqid'} . ":" . bioint::gff3::get_pos(\%gff). "\t" . $_, $cds);
    # }
}


#===SUBROUTINES=================================================================



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
