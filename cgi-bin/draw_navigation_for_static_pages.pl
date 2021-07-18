#!/usr/bin/perl

# call this with .shtml files as <!--#include virtual="/cgi-bin/draw_navigation_for_static_pages.pl?0main&1yruu&2sf&basics" -->

# this file simply acts as a shell to be called by .shtml files.  This file
# will call draw_navigation just as journal.pl does.

# See draw_navigation for documentation

print "Content-type: text/html\n\n";

require "draw_navigation.pl";

&draw_navigation($ENV{"QUERY_STRING"});

