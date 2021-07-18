#!/usr/bin/perl -w
######################################################################
#
# source_viewer.pl displays its own source code, or the source code of
# a filename sent to it.  It blocks the source of some files from
# being viewed.
#
# Copyright (C) 2005 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

use strict;
use CGI qw(:all);
use File::Basename;

require "draw_navigation.pl";
require "allowSource.pl";
require "mkdef.pl";
require "log_writer.pl";

my($query,$file);

$query = new CGI;									 

$| = 1;        # if set to nonzero, forces a flush after every write or print

$file = $query->param('file');
# only display something that starts with alphanumerics (or _), and then possibly ends with ".pl" ".pm" or ".cgi"
unless ((length($file) < 50) && ($file =~ m/^[_[:alnum:]]+(\.pl|\.pm|\.cgi)?$/m)) {
    warn ("sourceViewer will not display " . $file);                    #  . " because it contains " . $badchars);
    &write_log ("source", "sourceViewer will not display " . $file);    #  . " because it contains " . $badchars);
    $file=basename($0);    # basename($0) = this script name
}									 

&write_log ("source", $file);

my @no = qw(404 gaba journal search setup comment draw ~); # files containing these names may not be viewed

foreach (@no) {
    if($file =~ $_) {
	print $query->header, $query->start_html("Not all source code is free.");
	&draw_navigation("0main&none");
	print $query->end_html;
	die "\n";
    }
}

# else
print $query->header, $query->start_html("Source of $file");
&draw_navigation("0main&none");

if (-f $file) {
    my $file_contents;
    local $/;      # file slurp mode
    open (IN, "$file") or die "Can't open $file for reading";
    $file_contents = <IN>;
    print "\n<p>" . $query->start_form, "\n";

    print $query->textarea(-name=>'source',
			   -default=>"$file_contents",
			   -rows=>40,
			   -columns=>150);
    print $query->end_form;
}   # if $file

print $query->end_html;

&allowSource;
