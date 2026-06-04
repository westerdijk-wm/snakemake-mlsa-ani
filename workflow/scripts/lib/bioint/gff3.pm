#!/usr/bin/perl

# bioint::gff3

use strict;
use FindBin;                     # locate this script
use lib "$FindBin::RealBin/../../lib";  # use the parent directory


# Biont SAM package
package bioint::gff3;

sub gff_clean {
    # Clean up GFF3 entries by filling in '.' when needed
    my ($hash) = @_;
    my @field = qw/seqid source type start end score strand phase/;
    my @attribute = qw/ID Name Alias Parent Target Gap Derives_from Note Dbxref Ontology_term Is_circular/;
    my %done;
    for (@field) {
	$done{$_}++;
	$hash->{$_} = "." unless $hash->{$_};
	# Could check format for constraints of correct GFF3
    }
    for (@attribute) {
	# Could check format for constraints of correct GFF3
	if ("@field" =~ /\b$_\b/) {
	    # attribute name matches a standard field name
	    die "ERROR: attribute contains '$_' that is a reserved name for a column\n";
	}
	$done{$_}++;
    }
    for (keys %$hash) {
	next if $done{$_};
	if (/^[A-Z]/) {
	    # Upper case attributes are strictly specified in the docs
	    die "ERROR: incorrect field ('$_') encountered in\n" . gff_string($hash) ."\n";
	}
    }
}
    
sub gff_string {
    # Convert GFF3 hash to a GFF3 string
    my ($hash) = @_;
    my @field = qw/seqid source type start end score strand phase/;
    my @attribute = qw/ID Name Alias Parent Target Gap Derives_from Note Dbxref Ontology_term Is_circular/;
    my %done;
    my @list;
    for (@field) {
		push @list, $hash->{$_};
		$done{$_}++;
    }
    # combine attributes together
    my $string = "";
    for (@attribute) {
		next unless defined $hash->{$_};
		$string .= ";" if $string;
		$string .= $_ . '=' . $hash->{$_};
		$done{$_}++;
    }
    for (sort keys %$hash) {
		next if $done{$_};
		if (/^[A-Z]/) {
	    	# Upper case attributes are strictly specified in the docs
	    	die "ERROR: incorrect field ('$_') encountered in\n" . gff_string($hash) ."\n";
		} else {
	    	# Add extra lower case attribute
	    	$string .= ";" if $string;
	    	$string .= $_ . '=' . $hash->{$_};
	    	$done{$_}++; # not used yet, maybe later?
		}
    }
    push @list, $string;
    return join("\t", @list);
}

sub parse_gff {
    # Reads a GFF3 file line by line and converts each entry to a hash
    my ($line, $hash) = @_;
    $_ = $line;
    my @field = qw/seqid source type start end score strand phase/;
    my @attribute = qw/ID Name Alias Parent Target Gap Derives_from Note Dbxref Ontology_term Is_circular/;
    s/\R+//;
    my @col = split/\t/;
    # Are comments useful?
    if (/^\s*#/) {
	return;
    } else {
	for my $i (0..$#col) {
	    if ($i < scalar @field) {
		$hash->{ $field[$i] } = $col[$i];
	    } else {
		# Attributes (should be only one column officially
		for (split/;/, $col[$i]) {
		    my ($key, $value) = split/=/;
		    if ("@field" =~ /\b$key\b/) {
			# attribute name matches a standard field name
			die "ERROR: attribute contains '$key' that is a reserved name for a column\n$line\n";
		    }
		    $hash->{ $key } = $value;
		}
	    }
	}
    }
    return;
}

sub get_pos {
    # Get position string (GenBank style) for GFF line
    my ($entry) = @_;
    my @set;
    my $pos;
    if (ref $entry eq 'ARRAY') {
	@set = @$entry;
    } else {
	my @gap = split/ /, $entry->{'Gap'};
	@gap = reverse @gap if $entry->{'strand'} eq '-';
	my $p = $entry->{'start'};
	$pos = $p . "..";
	$p -= 1;
	if (@gap) {
	    my $intron;
	    for (@gap) {
		my $type = substr($_, 0, 1, "");
		my $len = $_;
		if ($type eq "D") {
		    # intron
		    $intron++;
		    $pos .= $p;
		    $p += $len;
		    $pos .= "," . ($p + 1) . "..";
		} else {
		    $p += $len;
		}
	    }
	    # Check that it matches end
	    $pos .= $p;
	    die "ERROR: end position based on Gap is '$p', but it should be " . $entry->{'end'} unless $p eq $entry->{'end'};
	    $pos = "join($pos)" if $intron;
	} else {
	    $pos .= ".." . $entry->{'end'};
	}
    }
    $pos = "complement($pos)" if $entry->{'strand'} eq '-';
    return $pos;
}

# sub new {
#     my ($class, %args) = @_;
#     return bless \%args, $class;
# }

# sub get_provenance {
# 
# }

1;
