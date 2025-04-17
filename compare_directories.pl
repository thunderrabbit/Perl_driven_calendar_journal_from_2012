#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Spec;

# take two args: first‐tree and second‐tree
my ($tree1, $tree2) = @ARGV;
die "Usage: $0 <html‐tree> <second‐tree>\n" unless $tree1 && $tree2;

find({
    wanted => sub {
        return unless /\.html$/;               # only look at .html
        my $path1 = $File::Find::name;         # full path in tree1
        # compute relative path under tree1
        my $rel    = File::Spec->abs2rel($path1, $tree1);
        # build candidate paths under tree2
        my $html2  = File::Spec->catfile($tree2, $rel);
        (my $md_rel = $rel) =~ s/\.html$/.md/;  # swap extension
        my $md2    = File::Spec->catfile($tree2, $md_rel);

        if (-e $html2 or -e $md2) {
            my $found = -e $html2 ? ".html" : ".md";
            print "$rel => exists as $found in second tree\n";
        }
    },
    no_chdir => 1,
}, $tree1);
