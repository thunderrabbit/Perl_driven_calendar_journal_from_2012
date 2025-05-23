#!/usr/bin/perl

print "Content-type: text/html\n\n";

require "setup_journal.pl";

use CGI qw(:all);
use CGI::Cookie;
use Cwd qw( abs_path );     # allows Perl 5.26 to include local module date_smurfer.pm
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));
use lib "/home/barefoot_rob/dev/Text-RobMiniMarkdown/lib";  # CPAN-friendly development directory


my($query);
$require_reload = 0; # this will be set if the parameters had to be tweaked and the URL needs to be refreshed

$query = new CGI;

$| = 1;        # if set to nonzero, forces a flush after every write or print

$debug = $query->param('debug');


if($date = $query->param('date'))
{
    $date =~ s!^[\./~]*!!;   # chop off any number of . / or ~ chars at start of $date
    $date =~ s!/\.\.!!g;     # chop out any number of /.. within $date
    $date =~ s!/$!!;         # chop off very end / if it exists
}
else {
    $date = "nil";
}

$printer_version = $query->param('print');

# snag the journal type, and confirm it's valid
$journal_type = $query->param('type');
unless ($journal_regex_type{$journal_type}) {
    $journal_type = "all";
    $require_reload = 1;
}

$indexname = "$journal_base/preformatted_index_for_" . $journal_type . "_entries.html";

require "displayFile.pl";
require "draw_header.pl";
require "draw_navigation.pl";
require "sidebar.pl";             # Note that sidebar() sets $year, $month, $day, $lastday, and $nextday.
require "mainbar.pl";

&draw_header;
exit if ($date eq "nil" || $require_reload);   # if date is nil, then header drew a refresh-to-correct-date screen.

print "<body>\n";
&draw_navigation("0main&1journal&2$journal_type");

#print "<p><b>Oops.</b>  I just broke my journal in a bad way.  ETA = ?  <br/>for now, use <a href=\"http://m.robnugen.com/j\">my mobile journal</a> - Rob!</p>";
print "\n<table border=\"1\" width=\"100%\"><tr>\n";

#########################
#
#  2006 sep 9
#  $printer_version is a pretty rough hack, the code below was copied from sidebar.  It should actually NOT be in sidebar, but calculated up above and
#  then sidebar is called or not depending on the results.
#
#  THE CODE IS ALSO COPIED TO draw_header.pl, FURTHER PROVING IT SHOULD BE DONE FIRST BEFORE EITHER draw_header OR sidebar IS RUN.
#
#########################
if ($printer_version) {
    local $/;      # file slurp mode
    open LSONER, $ls1rfile;
    $ls1r = <LSONER>;

    unless ($date =~ m!^\d\d\d\d(?:/|$)!m) {
	# if date does not start with a four digit year, then grab the Latest Date as defined in the ls1R.html file
	($date) = $ls1r =~ m/LATEST ENTRY DATE: (.*)/m;
    }

    ($year, $month, $day) = split /\//, $date;

    $month = "$year/$month";
    $day = "$month/$day";
}
else
{
    print "\n<td class=\"sidebar\">";
    # # snag the journal type, and confirm it's valid
    &sidebar($date,$indexname);
    print "</td>";
}

    print "\n<td class=\"mainbar\">";

$debug && print "Here we print the journal entries for $date.\n";
$debug && print "<br>year $year\n";
$debug && print "<br>month $month\n";
$debug && print "<br>day $day\n";
$debug && print "<br>last $lastday\n";
$debug && print "<br>next $nextday\n";

#  This table goes around the prev_day next_day and printable_version at top of main bar
print "\n<table border='0' width='100%'><tr>";
unless ($printer_version) {
    if($day) {
	print "<td>\n";
	if($lastday) {
	    print "<a href=\"$journal_pl?type=$journal_type&amp;date=$lastday\">prev day</a> ";
	} else {
	    print "prev day ";
	}
	if($nextday) {
	    print "<a href=\"$journal_pl?type=$journal_type&amp;date=$nextday\">next day</a>";
	} else {
	    print "next day";
	}
	print "</td>\n";
    }
    print "<td align=\"right\"><a href=\"$journal_pl?type=$journal_type&amp;date=$day&amp;print=1\">printable version</a></td>";
}
print "</tr></table>\n";

&mainbar($day,$journal_type);  # $day contains the year and month


unless ($printer_version) {
    if($day) {
	if($lastday) {
	    print "<a href=\"$journal_pl?type=$journal_type&amp;date=$lastday\">prev day</a> ";
	} else {
	    print "prev day ";
	}
	if($nextday) {
	    print "<a href=\"$journal_pl?type=$journal_type&amp;date=$nextday\">next day</a>";
	} else {
	    print "next day";
	}
    }
}

print "</td></tr></table>\n";
print "</body></html>\n";

