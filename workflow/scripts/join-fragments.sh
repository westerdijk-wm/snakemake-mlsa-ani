IFS='' read -r -d '' perl_script <<"EOF"
#!/usr/bin/perl
use strict;
use warnings;

#===MAIN========================================================================

# Hash to store the sequences: key (id and defintion) and value (sequence) 
my %fas_data;
# Array to store the order of the sequences
my @ids;




# If there were arguments specified then read the sequence from them
# OR read from STDIN
if (@ARGV) {
    for (@ARGV) {
	&read_fasta(\%fas_data, \@ids, $_);
    }
} else {
    &read_fasta(\%fas_data, \@ids);
}

my @complete;
my @fragmented;
for (@ids) {
    if (/missing:\(0;0\)/) {
        push @complete, $_;
    } else {
        push @fragmented, $_;
    }
}
# my @fragmented = grep {$_ !~ /missing:\(0;0\)/} @ids;
# my @complete = missing:(0;0)


my %loci;
for my $id (@fragmented) {
    $id =~ /\[([^\]]+)\]/;
    my $info = $1;
    my @tab = split/\t/, $info;
    my ($ref, $locus) = split/\|/, $tab[0];
    my $cov = substr($tab[2], 4);
    # print "locus:$locus $cov\n";
    push @{ $loci{$locus} }, $id;
}


my %used;
for my $locus (sort keys %loci) {
    my @seqids = @{ $loci{$locus} };
    my $total;
    my $weighted;
    my $ref;
    for my $id (@seqids) {
        $id =~ /\[([^\]]+)\]/;
        my $info = $1;
        my @tab = split/\t/, $info;
        $ref = $tab[0];
        # my ($ref, $locus) = split/\|/, $tab[0];
        my $cov = substr($tab[2], 4);
        my $sim = substr($tab[1], 4);
        $weighted += $sim * $cov;
        $total += $cov;
    }
    if ($total >= 1) {
        # Should be good to join
        my @sorted = sort sort_missing @seqids;
        if (scalar(@sorted) == 2 && $sorted[0] =~ /missing:\(0;/ && $sorted[1] =~ /missing:\(\d+;0\)/) {
            my $seq1 = $fas_data{$sorted[0]};
            my $seq2 = $fas_data{$sorted[1]};
            my $start = substr($seq2, 0, 11);
            if ($seq1 =~ /($start(.*))/) {
                my $overlap = $1;
                if ($seq2 =~ /^$overlap/) {
                    my $seq = $seq1 . substr($seq2, length($overlap));
                    my $len = length($seq);
                    my $sim = $weighted/$total;
                    my ($id, $node1) = split/\s+/, $sorted[0];
                    my ($id2, $node2) = split/\s+/, $sorted[1];
                    my $header = join("\t", $id, "merged:$node1+$node2", "[$ref", sprintf("sim:%.2f", $sim), "cov:1.00", "missing:(0;0)]");
                    # print ">$header\n$seq";
                    $fas_data{$header} = $seq;
                    push @complete, $header;
                    $used{$sorted[0]}++;
                    $used{$sorted[1]}++;
                }
            }
        }
    }
}

print_fasta(\%fas_data, \@complete);
my @keep;
for (@fragmented) {
    unless ($used{$_}) {
        push @keep, $_;
    }
}
print_fasta(\%fas_data, \@keep);

#print join("\n", @fragmented) . "\n";

#===SUBROUTINES=================================================================

sub sort_missing {
    $a =~ /missing:\((\d+)/;
    my $a_start = $1;
    $b =~ /missing:\((\d+)/;
    my $b_start = $1;
    $a_start <=> $b_start;
}

sub to_fasta {
    # Return a fasta formated string
    my ($seq_name, $seq, $len) = @_;
    # default to 60 characters of sequence per line
    $len = 60 unless $len;
    my $formatted_seq = ">$seq_name\n";
    while (my $chunk = substr($seq, 0, $len, "")) {
	$formatted_seq .= "$chunk\n";
    }
    return $formatted_seq;
}


sub print_fasta {
    # Print all the sequences to STDOUT
    my ($hash, $list) = @_;
    for (@$list) {
	print &to_fasta($_, $hash->{$_});
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
	if (/>(.*)/) {
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
EOF

# Create temp perl file
# cmd_file="${snakemake_rule}.pl" 
cmd_file="${snakemake[rule]}_${snakemake_wildcards[sample]}.pl"
echo "${perl_script}" >$cmd_file


# run code
perl $cmd_file "${snakemake_input[0]}"  > "${snakemake_output[0]}" 2>> "${snakemake_log[0]}"
code=$?

# Clean up
rm $cmd_file
exit $code
