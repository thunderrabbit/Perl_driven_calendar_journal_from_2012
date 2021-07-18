#!/usr/bin/perl

require "setup_journal.pl";
require "log_writer.pl";

use CGI qw(:all);
use CGI::Cookie;

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

print "Content-type: text/html\n\n";

require "displayFile.pl";
require "draw_header.pl";
require "draw_navigation.pl";
require "sidebar.pl";             # Note that sidebar() sets $year, $month, $day, $lastday, and $nextday.
require "mainbar.pl";

&draw_header;
exit if ($date eq "nil" || $require_reload);   # if date is nil, then header drew a refresh-to-correct-date screen.

&write_log("journal","$date $journal_type");

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
#  THE CODE IS ALSO COPIED TO draw_heder.pl, FURTHER PROVING IT SHOULD BE DONE FIRST BEFORE EITHER draw_header OR sidebar IS RUN.
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

# change draw_navigation.pl at the bottom as well
print<<TWITTER;
<script type="text/javascript" src="http://twitter.com/javascripts/blogger.js"></script>
<script type="text/javascript" src="http://twitter.com/statuses/user_timeline/thunderrabbit.json?callback=twitterCallback2&count=1"></script>
TWITTER

# print<<OLARK;
# <!-- begin olark code --> <script type='text/javascript'>/*<![CDATA[*/ window.olark||(function(k){var g=window,j=document,a=g.location.protocol=="https:"?"https:":"http:",i=k.name,b="load",h="addEventListener";(function(){g[i]=function(){(c.s=c.s||[]).push(arguments)};var c=g[i]._={},f=k.methods.length;while(f--){(function(l){g[i][l]=function(){g[i]("call",l,arguments)}})(k.methods[f])}c.l=k.loader;c.i=arguments.callee;c.p={0:+new Date};c.P=function(l){c.p[l]=new Date-c.p[0]};function e(){c.P(b);g[i](b)}g[h]?g[h](b,e,false):g.attachEvent("on"+b,e);c.P(1);var d=j.createElement("script");m=document.getElementsByTagName("script")[0];d.type="text/javascript";d.async=true;d.src=a+"//"+c.l;m.parentNode.insertBefore(d,m);c.P(2)})()})({loader:(function(a){return "static.olark.com/jsclient/loader1.js?ts="+(a?a[1]:(+new Date))})(document.cookie.match(/olarkld=([0-9]+)/)),name:"olark",methods:["configure","extend","declare","identify"]}); olark.identify('9366-567-10-9443');/*]]>*/</script> <!-- end olark code -->
# OLARK

print "</body></html>\n";

