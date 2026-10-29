#!/usr/bin/perl
# reindent.pl ORIGINAL TIDIED > OUT
#
# Emit ORIGINAL with each line's leading whitespace replaced by the
# leading whitespace of the same-numbered line of TIDIED (tabs in that
# run expanded at 8). Everything after the leading whitespace is the
# original byte for byte, so the result differs from ORIGINAL only in
# indentation. Dies if the two files have different line counts.
use strict;
use warnings;

my ($orig_file, $tidy_file) = @ARGV;
die "usage: $0 ORIGINAL TIDIED\n" unless defined $tidy_file;

my @orig = read_lines($orig_file);
my @tidy = read_lines($tidy_file);
die sprintf("line counts differ: %s has %d, %s has %d\n",
            $orig_file, scalar @orig, $tidy_file, scalar @tidy)
    unless @orig == @tidy;

for my $i (0 .. $#orig) {
    my ($lead) = $tidy[$i] =~ /^([ \t]*)/;
    (my $rest = $orig[$i]) =~ s/^[ \t]*//;
    $lead = expand_tabs($lead);
    print $rest =~ /^\n?$/ ? $rest : $lead . $rest;
}

sub read_lines {
    my ($file) = @_;
    open(my $fh, '<', $file) or die "can't open $file: $!";
    my @lines = <$fh>;
    close $fh;
    return @lines;
}

sub expand_tabs {
    my ($s) = @_;
    my $out = '';
    for my $c (split //, $s) {
        if ($c eq "\t") { $out .= ' ' x (8 - length($out) % 8); }
        else            { $out .= $c; }
    }
    return $out;
}
