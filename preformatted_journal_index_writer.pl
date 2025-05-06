#!/usr/bin/perl -w

use Cwd qw( abs_path );     # allows Perl 5.26 to include local file setup_journal.pl
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));

require "setup_journal.pl";


# create an RSS 1.0 file (http://purl.org/rss/1.0/)
use XML::RSS;
use Date::Manip qw(ParseDate UnixDate);  # used in creating RSS feed below

# ================================================
# I put a zero as the zeroth element, so $months[1] means January = 31
# I put a zero as the second element, cause it will be either 28 or 29
@month_lengths = (0, 31, 0, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
@month_titles_spaced_for_month_summaries = ( "         ",
  "      Jan", "      Feb", "      Mar", "      Apr",
        "      May", "     June", "     July", "      Aug",
        "     Sept", "      Oct", "      Nov", "      Dec",
);
@month_titles_no_spacing = ( "",
  "jan", "feb", "mar", "apr", "may", "jun",
  "jul", "aug", "sep", "oct", "nov", "dec",
);

sub iMayRunYet {
    # open a file to see if it's been at least an hour since last run
    my $filename = "/home/barefoot_rob/preformatted_last_run.txt";
    my $last_run = 0;
    if (-e $filename) {
        open (LASTRUN, $filename);
        $last_run = <LASTRUN>;
        close LASTRUN;
    }
    my $now = time;
    if ($now - $last_run > 1*60*60) {
        open (LASTRUN, ">$filename");
        print LASTRUN $now;
        close LASTRUN;
        return 1;
    } else {
        return 0;
    }
}

if (!&iMayRunYet) {
    print "Content-type: text/html\n\n";
    print "Wait an hour before running again.";
    exit;
}

sub setFeb {
    local($year) = @_;

    if (&isLeap($year)) { $month_lengths[2]=29; }
    else { $month_lengths[2]=28; }
}

sub isLeap {
    local($year) = @_;
    if ($year % 4 == 0) {
        if ($year % 100 == 0) {
            if ($year % 400 == 0) { 1; }
            else { 0; }
        } else { 1; }
    } else { 0; }
}

sub doomsday {
    my $year = shift;

    $year = ( localtime(time) )[5] unless $year;
    if ($year < 1583) {
        warn "The Gregorian calendar did not come into use until 1583. Your date predates the usefulness of this algorithm."
    }

    my $century = $year - ( $year % 100 );
    my $base = ( 3, 2, 0, 5 )[ ( ($century - 1500)/100 )%4 ];
    my $twelves = int ( ( $year - $century )/12);
    my $rem = ( $year - $century ) % 12;
    my $fours = int ($rem/4);
    my $doomsday = $base + ($twelves + $rem + $fours)%7;

    return $doomsday % 7;
}

sub dayofweek {
    my ($day, $month, $year) = @_;

    # When is doomsday this year?
    my $doomsday = &doomsday( $year );

    # And when is doomsday this month?
    my @base = ( 0, 0, 7, 4, 9, 6, 11, 8, 5, 10, 7, 12 );
    @base[0,1] = &isLeap($year) ? (32,29) : (31,28);

    # And how far after that are we?
    my $on = $day - $base[$month - 1];
    $on = $on % 7;

    # So, the day of the week should be doomsday, plus however far on we are
    return ($doomsday + $on) % 7;
}

chdir ("$journal_base");
local $/;     # $/ is the eoln marker.  This makes file reads be file slurps!
$journal_directory = <>;
system "ls -1R $journal_directory > ls-1R2.txt";
open (LSONER, "ls-1R2.txt");
$ls1r = <LSONER>;

@pre_month_whitespace = ( "",
#       jan             feb   mar   apr
        "&nbsp;&nbsp;", "  ", "  ", "  ",
#       may             jun   jul   aug
        "&nbsp;&nbsp;", "  ", "  ", "  ",
#       sep             oct   nov   dec
        "&nbsp;&nbsp;", "  ", "  ", "  ",
);

@post_month_whitespace = ( "",
#       jan  feb  mar  apr
        "",  "",  "",  "  \n",
#       may  jun  jul  aug
        "",  "",  "",  "  \n",
#       sep  oct  nov  dec
        "",  "",  "",  "  \n",
);

my $HOURS_FROM_CALI_TO_TOKYO = 16;  # add N hours worth of seconds to get from California time to Japan time.  This will have to change at Daylight Saving shifts, but we actually don't care about just 1 hour.

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $HOURS_FROM_CALI_TO_TOKYO*60*60);
my $JST_yyyy = ($year + 1900);
my $JST_mm = ($mon + 1);
my $JST_dd = $mday;


# %journal_regex_type is defined in setup_journal.pl
foreach $journal_type (keys %journal_regex_type) {

    my $rss;
    undef $rss;

# Create an RFC822 compliant date (current time)
my $rfc822_format = "%a, %d %b %Y %H:%M %Z";
my $today         = ParseDate("Now");

my $rfc822_date   = UnixDate($today,$rfc822_format);

    $rss = new XML::RSS (version => '2.0');
    $rss->channel(
		  title        => "Keep pushing the limits.",
		  link         => "http://robnugen.com",
		  description  => "$journal_type entries by Rob Nugen",
		  dc => {
		      lastbuilddate       => $rfc822_date,
		      subject    => "Rob's Life",
		      creator    => 'rob@robnugen.com (Rob Nugen)',
		      publisher  => 'rob@robnugen.com (Rob Nugen)',
		      rights     => 'Copyright 1985, 1987, 1988, 1990, 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2016, Rob Nugen',
		      language   => 'en-us',
		  },
		  syn => {
		      updatePeriod     => "hourly",
		      updateFrequency  => "7",
		      updateBase       => "Wed, 25 Mar 1970 00:00:00 EST",
		  }   # need comma if next structure is used but,
		  );


    # these hashes will basically store all the results of scanning through ls-1R.txt looking for matching filenames
    # At the end, we can loop through these hashes and produce all the preformatted HTML journal.pl needs.
    undef %list_of_years_per_journal_type;
    undef %list_of_months_per_year;
    undef %list_of_days_per_year_month;

    my ($current_yyyy, $current_mm, $current_dd);

    # The preformatted HTML will be written to this file.
    my  $indexname = "$journal_base/preformatted_index_for_" . $journal_type . "_entries.html";
    open HTML_OUTPUT, ">$indexname" or die "can't open $indexname: $!";

    print HTML_OUTPUT "<html><body>\n\n";

    print HTML_OUTPUT "<p>run on yyyy/mm/dd: $JST_yyyy/$JST_mm/$JST_dd</p>";

=pod
	For each yyyy/mm: combination in ~/journal/ls-1R.txt, grab all the
	filenames for that month.  We'll therefore have the year, month,
	and filenames (which include dates).  We'll scan the filenames to
	see if they match the $journal_regex_type{$journal_type}, and if
	they do, we know it should be included in this output.
=cut
 	while($ls1r =~ m!^\./(\d\d\d\d)/([^:]*?):.*?$(.*?\n\n)!smg)
{
    $year = $1;
    $month = $2;
    $files = $3;

    # An array of all the files in this yyyy/mm combination that match the regex
    @files_of_this_type = ();
    @files_of_ANY_type = ();

    # doing this so we don't match \d\d in the middle of words
    @files_of_ANY_type = split(/\n/,$files);

    # Get all the files from this year/month that match the regex for this filetype.
    foreach (@files_of_ANY_type) {
	if ($_ =~ m!$journal_regex_type{$journal_type}!i) {
	    push (@files_of_this_type, $_);
	}
    }

    if (@files_of_this_type)
    {

	my $filename;
	# Now is where the work begins.  We know what year/month we're looking
	# at, and we have confirmed that there are files in that month that
	# match the regex.  Remember this year has such files.  Remember this
	# year/month has files.  Remember this year/month/day has files.

	# add this year to this journal_types list
	$list_of_years_per_journal_type{$year} = "Y";

	# add this month to this year's list of months with these files
	$list_of_months_per_year{$year}->{$month} = "Y";

	foreach $filename (@files_of_this_type) {

	    unless ($filename =~ m/.*\.comment~*$/) {      # keep comments from being displayed
		unless ($filename =~ m/.*\~$/) {      # keep backups from being displayed

		    ($dd) = $filename =~ m!_?(\d\d)!m;
		    # add this day to this year_months list
		    $list_of_days_per_year_month{"$year/$month"}->{$dd} = "Y";

		    # pop an item off if there are already 15 items
		    pop (@{$rss->{'items'}}) if (@{$rss->{'items'}} == 15);

		    $file = $filename;
		    ($title) = $file =~ m!_?\d\d(.*)\.(?:html|txt)$!;

		    $title_no_spaces = $title;
		    $title_no_spaces =~ s/_/ /g;  # basically the title of the entry

		    unless ($year > $JST_yyyy ) {      # there is one entry dated 2016

			$rss->add_item(title => "$year/$month/$dd: $title_no_spaces",
				       link  => $www_journal_pl . "?type=" . $journal_type . "&amp;date=" . $year . "/" . $month . "/" . $dd . "#" . $title,
				       guid  => $www_journal_pl . "?type=" . $journal_type . "&amp;date=" . $year . "/" . $month . "/" . $dd . "#" . $title,
				       mode => "insert"  # put them so that most recent shows up first
				       );
 		    } # unless year > this year

		    # (in $current_xxxx), keep track of the date closest to, but not beyond, today ($JST_xxxx).
		    ($current_yyyy,$current_mm,$current_dd) = ($year,$month,$dd) unless ($year > $JST_yyyy ||
											 ($year == $JST_yyyy && $month > $JST_mm) ||
											 ($year == $JST_yyyy && $month == $JST_mm && $dd > $JST_dd));

		    if ($dd > 31) {
			$error_message .= "<p><b>for $year/$month we got day = $dd from $filename</b></p>";
		    }
		} # unless it's a backup.file~
	    } # unless it's a comment
	} # grab each date from list of files
    } # there are matching files this year/month
} # grab all the files from this year/month

print HTML_OUTPUT "<p><!-- $journal_type journal entries match m!$journal_regex_type{$journal_type}!ig --></p>\n\n";

print HTML_OUTPUT "YEARS: ";
print HTML_OUTPUT join ", ", (sort keys %list_of_years_per_journal_type);
print HTML_OUTPUT "\n\n";

print HTML_OUTPUT "<p><!-- YEAR SUMMARIES --></p>\n\n";
####### PRINT HTML_OUTPUT YEAR SUMMARIES ##################
foreach $year (sort keys %list_of_months_per_year) {

    print HTML_OUTPUT "MONTHS $year: ";
    print HTML_OUTPUT join ", ", (sort keys %{ $list_of_months_per_year{$year} });
    print HTML_OUTPUT "\n\n";

    print HTML_OUTPUT "$year:\n";
    print HTML_OUTPUT "<pre class='calendar'>\n";
    print HTML_OUTPUT "         <a href=\"$journal_pl?type=$journal_type&amp;date=$year\">$year</a>        \n";
    foreach $i (1..12) {
	$month = sprintf "%2.2d", $i;
	print HTML_OUTPUT $pre_month_whitespace[$month];

	if ($list_of_months_per_year{$year}->{$month}) {
	    print HTML_OUTPUT "<a href=\"$journal_pl?type=$journal_type&amp;date=$year/$month\">".
		$month_titles_no_spacing[$month]."</a>";
	} else {
	    print HTML_OUTPUT "$month_titles_no_spacing[$month]";
	}
	print HTML_OUTPUT $post_month_whitespace[$month];
    }
    print HTML_OUTPUT "</pre>\n\n";
}


print HTML_OUTPUT "<p><!-- MONTH SUMMARIES --></p>\n\n";
####### PRINT HTML_OUTPUT MONTH SUMMARIES ##################
foreach $yearmonth (sort keys %list_of_days_per_year_month) {
    ($year,$month) = $yearmonth =~ m!(\d\d\d\d)/(\d\d)!;
    unless ($month =~ m/^\d\d$/) {next;}
    # Make sure month is exactly two digits before continuing.
    # (Month could be "costarica" or "images", for example.)

    # Now we are sure we have found a good month.

    setFeb($year);                             # 28 or 29 days depending on Leap Year
    $day_of_week = dayofweek(1,$month,$year);

    print HTML_OUTPUT "DAYS $year/$month: ";
    print HTML_OUTPUT join ", ", (sort keys %{ $list_of_days_per_year_month{"$year/$month"} });
    print HTML_OUTPUT "\n\n";

    print HTML_OUTPUT "\n\n$year/$month:\n";
    print HTML_OUTPUT "<pre class='calendar'>\n";
    # Split off the leading whitespace to keep it outside the link.
    $month_titles_spaced_for_month_summaries[$month] =~ m/(\s*)(.*)/;
    print HTML_OUTPUT "&nbsp;$1<a href=\"$journal_pl?type=$journal_type&amp;date=$year/$month\">$2 $year</a>\n";
    print HTML_OUTPUT "&nbsp;";
    print HTML_OUTPUT "   " x $day_of_week;
    foreach $i (1..$month_lengths[$month]) {
	$day = sprintf "%2.2d", $i;
	# Here is where we print HTML_OUTPUT the day number.
	# This needs to include newlines after each Saturday.
	if($list_of_days_per_year_month{"$year/$month"}->{$day}) {
	    print HTML_OUTPUT "<a href='$journal_pl?type=$journal_type&amp;date=$year/$month/$day'>$day</a>";
	} else {
	    print HTML_OUTPUT "$day";
	}
	if (++$day_of_week >= 7 ) {
	    print HTML_OUTPUT " \n";
	    if ($i != $month_lengths[$month]) { print HTML_OUTPUT "&nbsp;"; }
	    $day_of_week = 0;
	} else { print HTML_OUTPUT " "; }
    }
    print HTML_OUTPUT "</pre>\n\n";
}

# Write empty blocks for non-existant past / future months and years.
foreach my $when (qw(prev next)) {
    print HTML_OUTPUT "\nNO $when YEAR:\n<pre class='calendar'>\n \n \n \n \n</pre>\n\n";
    print HTML_OUTPUT "\nNO $when MONTH:\n<pre class='calendar'>\n \n \n \n \n \n \n</pre>\n\n";
}

# Calculate the first date for this $journal_type
my $first_year_month = (sort keys %list_of_days_per_year_month)[0];
my $first_entry_date = $first_year_month . "/" . (sort keys %{$list_of_days_per_year_month{$first_year_month}})[0];
print HTML_OUTPUT "<p>\nFIRST ENTRY DATE: $first_entry_date\n\n</p>";

print HTML_OUTPUT "<p>\nCURRENT ENTRY DATE: $current_yyyy/$current_mm/$current_dd\n\n</p>";

# Calculate the last date for this $journal_type
my $last_year_month = (sort keys %list_of_days_per_year_month)[-1];
my $latest_entry_date = $last_year_month . "/" . (sort keys %{$list_of_days_per_year_month{$last_year_month}})[-1];
print HTML_OUTPUT "<p>\nLATEST ENTRY DATE: $latest_entry_date\n\n</p>";

print HTML_OUTPUT "</body></html>\n";

close HTML_OUTPUT;

$rss->save($journal_base . "/" . $journal_type . "_entries.rss");


} # end of foreach $journal_type

print "Content-type: text/html\n\n";
print "<head>\n";
print "</head>\n";
print "<body>\n";

print $error_message if $error_message;
foreach $journal_type (keys %journal_regex_type) {
    my  $longname = "/journal/preformatted_index_for_" . $journal_type . "_entries.html";
print "<br><a href=\"$longname\">$journal_type index</a>";
print "<br><a href=\"$journal_pl?type=$journal_type\">$journal_type journal</a>";
print "<br><a href=\"/journal/" . $journal_type . "_entries.rss\">$journal_type RSS</a>";
}

