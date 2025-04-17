#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Spec;
use File::Basename qw(dirname);
use File::Path    qw(make_path);

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
            # print "$rel => exists as $found in second tree\n";
            my $html2 = File::Spec->catfile($tree2, $rel);

            print "NOT yet ⮕ Overwriting $md_rel with HTML: moving\n";

            # remove the Markdown
            unlink $md2
              or warn "⚠️  Could not remove $md2: $!\n";

            # move the HTML into place
            rename $path1, $html2
              or warn "⚠️  Could not move $path1 → $html2: $!\n";
        }
    },
    no_chdir => 1,
}, $tree1);
