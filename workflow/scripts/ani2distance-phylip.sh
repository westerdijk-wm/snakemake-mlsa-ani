IFS='' read -r -d '' perl_script <<"EOF"
#!/usr/bin/perl -w

use strict;

my $help = "Usage:\n" .
    "\t$0 [-h | --help] ani.tsv >ani-distance.phy\n\n" .
    "Description:\n" .
    "\tA tool to convert ANI tab separeted file into a distance matrix in phylip format\n\n" .
    "Options:\n" .
    "\t-h | --help\n" .
    "\t\tPrint help\n" .
    "\n";

if (grep{/^--?h(elp)?$/} @ARGV) {
    print $help;
    exit;
}

my @header;
my @rows;
my @range;
while (<>) {
    s/\R//g;
    my ($id, @scores) = split/\t/;
    # Header has no $id, header line should start with a tab
    if ($id) {
	# ANI score to distnace
	my @distances = map{ if (/^NaN?$/i) {"NA"} else {1 - $_} } map{if (/^(\d+(?:\.\d+)?)e-(\d+)$/i) {$1 * (10 **-$2)} else {$_} } @scores;
	print join("\t", $id, @distances), "\n";
    } else {
	# Header line of ANI table
	# Print phylip header
 	print "  " . scalar(@scores) . "\n";
    }
}
EOF

# Create temp perl file
cmd_file="${snakemake[rule]}.pl"
printf '%s\n' "$perl_script" > "$cmd_file"

perl "$cmd_file" \
    "${snakemake_input[0]}" \
    > "${snakemake_output[0]}"

status=$?

rm -f "$cmd_file"

exit $status