#!/usr/bin/perl -w

######################################################################
#
# allowSource.pl writes a link at the bottom of code I want to share
#
# USAGE:
#
# require "allowSource.pl";
# ... code ...
# &allowSource;
#
#
# Copyright (C) 2005-2006 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

use File::Basename;

my $file=basename($0);

sub allowSource {
    print "\n<p><hr />";
    print "\n<a href='/cgi-bin/source_viewer.pl?file=$file'>" . $file . " source</a> is free.</p>\n";
}

sub allowAjaxSource {
    my $out = "\n<p><hr />";
    $out .= "\n<a href='/cgi-bin/source_viewer.pl?file=$file'>" . $file . " source</a> is free.</p>\n";
    return $out;
}
1;

