#!/usr/bin/perl -w
use strict;

my ($mapfile, $file) = @ARGV;

if (@ARGV != 2 || grep{/^--?h(elp)?$/} @ARGV) {
    print STDERR "USAGE:\n" .
	"\t$0 <id-map.tsv>  <input.fas | input.tsv | input.nwk>\n" .
	"DESCRIPTION:\n".
	"\tA tool to replace IDs in FASTA, TSV and Newick files.\n" .
	"\tThe ID map file should be tab separated and the current and new IDs should be\n". 
	"\tthe first and second columns, respectively.\n" .
	"\tFor table files (TSV) it is important that the header row has to start with a tab,\n" .
	"\totherwise the header row will not be processed. Only row and column names are\n" .
	"\tupdated for tables.\n";
    exit;
}


open(my $inmap, '<', $mapfile) || die $!;
my %map;
while(<$inmap>) {
    s/\R+//;
    my ($k, $v) = split/\t/;
    $map{$k} = $v;
}

open(my $in, '<', $file) || die $!;
my $i;
while(<$in>) {
    $i++;
    # Table
    # header
    if ($i == 1 && /^\t/) {
	s/\R+//;
	my @new = map{ $map{$_} ? $map{$_} : $_ } split /\t/;
	$_ = join("\t", @new) . "\n";
    }
#    s/\t(.*?)\t/$map{$1}?"\t".$map{$1}."\t":"\t".$1."\t"/ge;
#    s/\t(.*?)\t/$map{$1}?"\t".$map{$1}."\t":"\t".$1."\t"/ge;
#    s/\t(.*?)$/$map{$1}?"\t".$map{$1}:"\t".$1/e;
    # row
    s/^(\S+.*?)\t/$map{$1}?$map{$1}."\t":$1."\t"/e;

    # fasta
    s/^>(\S+)/$map{$1} ? ">" . $map{$1} : ">" . $1/e;
    
    # nwk
    s/([^():,;]+)([:,)])/$map{$1}?$map{$1}.$2:$1.$2/ge;
    print;
}
