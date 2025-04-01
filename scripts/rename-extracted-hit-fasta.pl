#!/usr/bin/env perl
use warnings;
use strict;

# scripts/rename-extracted-gff-fasta.pl - -strain=GCF_001587155.1 > genes/gff/GCF_001587155.1.fas
#===DESCRIPTION=================================================================
my $description = "Description:\n\tA tool to rename FASTA ID lines.\n";
my $usage = "Usage:\n\t$0 [-h | --help] <FASTA file> -strain=<STRAIN ID>\n";
my $options = 
    "Options:\n" .
    "\t-h | --help\n\t\tPrint the help message; ignore other arguments.\n" .
    "\n";

#===MAIN========================================================================

&print_help(@ARGV);

my $strain = "";

my $infile;
for (@ARGV) {
    if (/^--?strain=(.*)$/) {
        $strain = $1;
    } else {
        if ($infile) {
            # Too many arguments
        } else {
            $infile = $_;
        }
    }
}

$infile = undef if $infile && $infile eq '-';
my $in;
if ($infile) {
	open $in, '<', $infile || die $!;
} else {
	$in = *STDIN;
}
while(<$in>) {
    if (/>/) {
        # Format the ID line to have
        # ><Strain ID>|<gene> <original ID>
        s/\R//g;
        my ($old_id, @rest) = split/\t/;
        $old_id =~ s/^>//;
        if (join("\t", @rest) =~ /ref:[^\|]+\|(\S+)/) {
            print ">$strain|$1 $old_id\t[" . join("\t", @rest) . "]\n";
        } else {
            print ">$strain|$old_id $old_id\n";
            print STDERR "WARNING: No gene ID found for '$_'\n"
        }
    } else {
        # Print as it is, nothing to change here
        print;
    }
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