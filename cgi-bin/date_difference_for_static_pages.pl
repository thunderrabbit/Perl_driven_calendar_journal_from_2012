#!/usr/bin/perl

# call this with .shtml files as <!--#include virtual="/cgi-bin/date_difference_for_static_pages.pl" -->

# this file simply acts as a shell to be called by .shtml files.  This file
# will call date_difference just as daysold.pl will eventually do

# See date_smurfer.pm for documentation

print "Content-type: text/html\n\n";

use date_smurfer;

print "<p>" . &date_difference($ENV{"QUERY_STRING"});
