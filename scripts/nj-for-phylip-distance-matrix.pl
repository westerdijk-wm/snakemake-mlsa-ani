#!/usr/bin/perl -w
use strict;

use Bio::Tree::DistanceFactory;
use Bio::Matrix::IO;
use Bio::TreeIO;
 

my $help = "Usage:\n" .
    "\t$0 [-h | --help] <distance-matrix.phy>|- >nj-tree.nwk\n\n" .
    "Description:\n" .
    "\tA tool to generate a neighbor-joining tree from a phylip format distance matrix\n\n" .
    "Input:\n" .
    "\t<distance-matrix.phy>\n" .
    "\t\tReads distance matrix from the specified file\n" .
    "\t-\n" .
    "\t\tReads distance matrix from STDIN (standard input)\n" .
    "Options:\n" .
    "\t-h | --help\n" .
    "\t\tPrint help\n" .
    "\n";

if (grep{/^--?h(elp)?$/} @ARGV) {
    print $help;
    exit;
}

my $input = $ARGV[0];

unless (@ARGV == 1) {
    die "ERROR: incorrect number of input specified (" . scalar(@ARGV) . ")\n\n" .
	$help;
}

if ($input ne '-' && ( ! -e $input || -z $input ) ) {
    die "ERROR: input file '$input' does not exist or it is empty\n\n" . $help;
}

# Create filehandle for the input file or STDIN ($input eq '-')
my $fh;
if ($input ne "-") {
    open $fh, '<', $input || die $!;
} else {
    print STDERR "Reading distance matrix from STDIN\n";
    $fh = \*STDIN;
}


# First line "   <int>" where is number of entries
# Other lines: "Strain 0.000000 0.004547 0.037825 0.039049" Where the strain name and distances are separated by /\s+/
# Same number of distances as entries, row and column order must be the same


my $dfactory = Bio::Tree::DistanceFactory->new(-method => 'NJ');
my $treeout = Bio::TreeIO->new(-format => 'newick');
my $parser = Bio::Matrix::IO->new(-format => 'phylip',
                                    -fh   => $fh);

my $mat  = $parser->next_matrix;
my $tree = $dfactory->make_tree($mat);
$treeout->write_tree($tree);

