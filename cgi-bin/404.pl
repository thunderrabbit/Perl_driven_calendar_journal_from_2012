#!/usr/bin/perl

use strict;
use CGI qw(:all fatalsToBrowser);
require "draw_navigation.pl";

# this code without revealing directory structures, was posted at http://robnugen.com/cgi-bin/journal.pl?type=all&date=2006/05/23

my ($subject,$match_quality,$body);
my %redirect_404s =      qw(
			    /skate/skate00.html             /cgi-bin/journal.pl?type=skate&date=1993/07/04#wild_skating_adventure
			    /skate/skate01.html             /cgi-bin/journal.pl?type=skate&date=1993/11/24#skate_Exxon_tunnels_Jesus_Saves
			    /skate/skate02.html             /cgi-bin/journal.pl?type=skate&date=1994/05/30#skate_pulled_by_truck
			    /skate/skate03.html             /cgi-bin/journal.pl?type=skate&date=1994/06/02#skate_ramp_birraporettis_wall
			    /skate/skate04.html             /cgi-bin/journal.pl?type=skate&date=1994/06/14#skate_George_R_Brown_disc_perceptions
			    /skate/skate05.html             /cgi-bin/journal.pl?type=skate&date=1994/07/01#skate_Woblong_Roberta
			    /skate/skate06.html             /cgi-bin/journal.pl?type=skate&date=1994/09/23#my_skating_accident
			    /skate/skate07.html             /cgi-bin/journal.pl?type=skate&date=1994/10/05#skate_recovery
			    /skate/skate08.html             /cgi-bin/journal.pl?type=skate&date=1994/12/13#skate_accident_fast_recovery
			    /skate/skate09.html             /cgi-bin/journal.pl?type=skate&date=1995/01/13#Skate_with_Roberta
			    /skate/skate10.html             /cgi-bin/journal.pl?type=skate&date=1995/01/20#skate_road_rash
			    /skate/skate11.html             /cgi-bin/journal.pl?type=skate&date=1995/11/24#skate_met_Jim_and_Nancy
			    /skate/skate12.html             /cgi-bin/journal.pl?type=skate&date=1995/12/23#Southside_Skate_Park_met_Laura
			    /skate/skate13.html             /cgi-bin/journal.pl?type=skate&date=1996/04/01#random_skate_stories
			    /skate/skate14.html             /cgi-bin/journal.pl?type=skate&date=1996/04/04#Southside_skate_park_bruising
			    /skate/skate15.html             /cgi-bin/journal.pl?type=skate&date=1996/04/05#pulling_skaters_is_good_for_your_legs
			    /skate/skate16.html             /cgi-bin/journal.pl?type=skate&date=1996/04/07#Memorial_Loop_Easter_skate
			    /skate/skate17.html             /cgi-bin/journal.pl?type=skate&date=1996/05/07#dark_night_skate
			    /skate/skate18.html             /cgi-bin/journal.pl?type=skate&date=1996/05/21#Olympic_skate_met_Kim_Zmeskal_and_Sonja
			    /skate/skate19.html             /cgi-bin/journal.pl?type=skate&date=1996/06/04#skated_Beltway_8_overpass_with_Marcel
			    /skate/skate20.html             /cgi-bin/journal.pl?type=skate&date=1996/07/19#car_surfing_skate
			    /skate/skate21.html             /cgi-bin/journal.pl?type=skate&date=1996/08/02#skate_frisbee_job_search
			    /skate/skate22.html             /cgi-bin/journal.pl?type=skate&date=1996/08/31#skating_in_Chicago
			    /skate/skate24.html             /cgi-bin/journal.pl?type=skate&date=1997/03/01#random_skating
			    /skate/skate25.html             /cgi-bin/journal.pl?type=skate&date=1997/03/08#lovely_Saturday_skate
			    /skate/skate26.html             /cgi-bin/journal.pl?type=skate&date=1997/03/13#skate_with_Diane_at_Rice_Stadium
			    /skate/skate27.html             /cgi-bin/journal.pl?type=skate&date=1997/10/14#fully_experienced_skate
			    /skate/skate28.html             /cgi-bin/journal.pl?type=skate&date=1997/10/16#skate_perfect_timing
			    /skate/skate29.html             /cgi-bin/journal.pl?type=skate&date=1997/11/26#third_annual_Thanksgiving_Eve_skate
			    /skate/skate30.html             /cgi-bin/journal.pl?type=skate&date=1997/11/27#thanksgiving_day_skate
			    /journal/1998/skate_with_diane.html   /cgi-bin/journal.pl?type=skate&date=1998/05/14#skate_with_diane
			    /journal/1998/skate_skinned_forearms.html  /cgi-bin/journal.pl?type=skate&date=1998/05/22#stream_of_conscious_skate_with_blood.html
			    /journal/1998/skate_and_imax.html       /cgi-bin/journal.pl?type=skate&date=1998/07/11#skate_and_imax
			    /journal/1998/skate_drum_corps.html     /cgi-bin/journal.pl?type=skate&date=1998/07/24#skate_drum_corps
			    /journal/1998/skate_galveston.html      /cgi-bin/journal.pl?type=skate&date=1998/10/13#skate_galveston
			    /journal/1998/skate_to_uh.html          /cgi-bin/journal.pl?type=skate&date=1998/11/11#skate_to_uh

			    /journal/1998/civil_war_past_life.html  /cgi-bin/journal.pl?type=all&date=1998/01/10
			    /journal/1998/butts_up.html             /cgi-bin/journal.pl?type=all&date=1998/10/18#butts_up_description
			    /journal/1998/christmas.html            /cgi-bin/journal.pl?type=all&date=1998/12/30#christmas
			    /journal/1998/soml_19-mar-1998.html     /cgi-bin/journal.pl?type=SoML&date=1998/03/19

			    /images/journal/2004/03/secret_byebye_party/secret_byebye_party.html  /images/travel/japan2003-2004/janette_fred/Page9.shtml

			    /images/journal/2002/03/thumbs/hethre.jpg   /images/YRUU/peeps/thumbs/hethre.jpg
			    /images/journal/2002/03/hethre.jpg   /images/YRUU/peeps/hethre.jpg
			    /images/journal/2002/11/jackie_(.*)  /images/peeps/Jackie_Purdy/jackie_
			    /images/journal/2003/12/frazz_outfit.gif  /images/funny/comics/frazz/frazz_outfit.gif

			    /sf                                    /yruu/sf/rules.shtml
			    /sf/                                    /yruu/sf/rules.shtml
			    /images/travel/japan2003-2004/daniel_Nov_2003  /images/travel/japan2003-2004/daniel_Nov_2004
			    /images/travel/japan2003-2004/worlds_shortest_escalator.jpg			    /images/travel/japan2003-2004/around_town/kawasaki/worlds_shortest_escalator.jpg
			    /images/travel/japan2003-2004/worlds_shortest_escalator_66k.jpg		    /images/travel/japan2003-2004/around_town/kawasaki/worlds_shortest_escalator_66k.jpg
			    /images/travel/Peaceboat/(.*)    /images/travel/Pb/
			    /images/journal/2003/09/purple_high_top_high_heels.jpg /images/travel/japan2003-2004/fashion/purple_high_top_high_heels.jpg
			    /images/journal/2004/09/dodonpa_ad.jpg   /images/travel/japan2003-2004/004fujikyu/dodonpa_ad.jpg
			    /images/journal/2004/09/concrete_mesh.jpg   /images/travel/japan2003-2004/hitomi/concrete_mesh.jpg
			    /images/journal/1998/tree/(.*)          /images/apt3/tree_fell/
			    /images/journal/1998/rally/(.*)         /images/YRUU/san_antonio_1998/

			    /images/journal/2002/07/swuusi/(.*)     /images/YRUU/SWUUSI2002/
			    /images/journal/2001/07/(.*)     /images/YRUU/SWUUSI2001/
			    /images/journal/2003/03/(.*)     /images/home/janette/dallas/
			    /images/journal/2003/02/wailua_falls_far_large.jpg  /images/travel/world/hawaii/kawaii/feb-2003/wailua/wailua_falls_far_large.jpg
			    /images/journal/2004/10/cool_escalator.jpg  /images/travel/japan2003-2004/around_town/yokohama/cool_escalator.jpg

			    /images/journal/2004/10/thumbs/Kiyomi_and_Hitomi.jpg  /images/travel/japan2003-2004/hitomi/thumbs/Kiyomi_and_Hitomi.jpg
			    /images/journal/2004/10/Kiyomi_and_Hitomi.jpg /images/travel/japan2003-2004/hitomi/Kiyomi_and_Hitomi.jpg
			    /images/journal/2004/10/(.*)   /images/travel/japan2003-2004/around_town/on_TJ-Bike/
			    /images/travel/japan2003-2004/around_town/on_TJ-Bike/Kiyomi_and_Hitomi.jpg /images/travel/japan2003-2004/hitomi/Kiyomi_and_Hitomi.jpg
			    /images/marble_track/(.*)      /images/art/marble_track/
			    /cgi-local/(.*)                /cgi-bin/
			    /wordpress(.*)                /blog
			    /R\.O\.B\.O\.T(.*)                /R.O.B.O.T.

			    /cgi-bin/journal$              /cgi-bin/journal.pl
			    /cgi-bin/CBC_source_viewer.pl  /cgi-bin/source_viewer.pl
			    /copyright.html                  /copyright.shtml
			    /dusty/writing/dreams            /writing/old/writing/dreams/
			    /alphabet_game.html              /writing/old/misc/alphabet_game.html
			    /thepin/index.html               /writing/thepin/
			    /thepin                          /writing/thepin/
			    /dusty/funny_classics/margins.html		    /writing/old/funny_classics/margins.html
			    /dusty/funny_classics/margins2.html		    /writing/old/funny_classics/margins2.html
			    /travel/peace_boat/49/2005-06-19_one_big_entry.shtml  /cgi-bin/journal.pl?type=all&date=2005/06/19
			    /web_stuff/funny_classics/destroy_earth.html  /writing/old/funny_classics/destroy_earth.html
			    /dusty/fgnet/   /writing/old/fgnet/index.html
			    /days/daysold.pl  /cgi-bin/daysold.pl
			    /safe/daysold_log.txt        /cgi-bin/source_viewer.pl?file=daysold.pl
			    /images/software/bad/google_spreadsheets_misspelling.png  /images/software/bad/com.google.www/google_spreadsheets_misspelling.png  
			    /images/software/bad/uh.edu_terrible_webpage.png   			    /images/software/bad/edu.uh.www/uh.edu_terrible_webpage.png
			    /images/software/bad/thumbs/(.*)   			    /images/software/bad/edu.uh.www/thumbs/
			    \b.*?(?:skate|skating).*\b  /cgi-bin/journal.pl?type=skate
			 );
my $refresh_to_URL; # in case we match a regex above

my $query = new CGI;

# the sort below makes / keys come before \ keys
foreach my $regex (sort keys %redirect_404s) {
    if  ($ENV{'REQUEST_URI'} =~ m!$regex!i) {
	$refresh_to_URL = $redirect_404s{$regex} . $1;
	$match_quality = ($regex =~ m!^/!) ? "nicely" : "generically";
	last;
    }
}

require "40rob.pl";

if ($ENV{'REMOTE_ADDR'} eq "125.0.17.214") {
    return &rob04;
    exit;
}

if ($refresh_to_URL) {
    print <<__END__;
Content-type: text/html

<head>
<meta http-equiv="refresh" content="0;url=$refresh_to_URL">
<script language=Javascript1.0>
  window.location.href="$refresh_to_URL"
  </script>
<!--  begin google-analytics code -->
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
    _uacct = "UA-163258-1";
urchinTracker();
</script>
<!--  end google-analytics code -->

</head>
<body>
redirecting to <a href="$refresh_to_URL">$refresh_to_URL</a>
</body>
__END__

    if ($ENV{"HTTP_COOKIE"}) {
	$subject = "* 404 Refreshed $match_quality: $ENV{'REQUEST_URI'}";
    } else {
	$subject = "404 Refreshed $match_quality: $ENV{'REQUEST_URI'}";
    }

    $body = $ENV{"REQUEST_URI"} . "-> http://robnugen.com$refresh_to_URL\n";
    $body .= $ENV{"HTTP_COOKIE"} . " " . $ENV{"REMOTE_HOST"} . "\n";
    $body .= ($ENV{"HTTP_REFERER"} || "no referer") . " \n " . $ENV{"HTTP_USER_AGENT"};

} else {

    print $query->header, $query->start_html("404: not found");

    &draw_navigation("0main&no_selection");

    print $query->h3("404: not found");

    print $query->p("I am rearranging lots on my site.  If there's something specific that you're looking for, try the navigation above.");

    print $query->p("An email is being sent to let me know what you were looking for.");
    print $query->end_html;

    if ($ENV{"HTTP_COOKIE"}) {
	$subject = "* 404 Not Found: $ENV{'REQUEST_URI'}";
    } else {
	$subject = "404 Not Found: $ENV{'REQUEST_URI'}";
    }

    $body = "http://robnugen.com" . $ENV{"REQUEST_URI"} ." \n";
    $body .= $ENV{"HTTP_COOKIE"} . " " . $ENV{"REMOTE_HOST"} . "\n";
    $body .= ($ENV{"HTTP_REFERER"} || "no referer") . " \n" . $ENV{"HTTP_USER_AGENT"};
}

if ($ENV{"HTTP_REFERER"} && $match_quality ne "nicely") {

    # only if http_referer exists, implying the page was not recrawled by a spider from its cache.

#   BEGIN  bit of code added 24 September 2005
    # The idea here is to search for a likely match to make it easier for me to find the correct URL.
    # Eventually I'd like to semi-automate the process of updating the refresh-hash used by this code.

    my ($filename,@filepath_array,@results);
    @filepath_array = split ('/', $ENV{"REQUEST_URI"});

    $filename = $filepath_array[$#filepath_array];

    @results = split ('\n', qx/find ~ | grep $filename/);   # qx executes the code and returns the results.  Money.

    if ($#results == -1) {
	# If there are no results
	$body .= "\nI didn't find anything that looked comprable.";
    }
    else
    {
	$body .= "\nTry one of these below:";
    }

    foreach (@results) {
	if (m!/home/barefoot_rob/temp.robnugen.com/!) {
	    s!/home/barefoot_rob/temp.robnugen.com/!!;
	    $body .= "\n " . "http://robnugen.com/$_";
	}
    }

#   END  bit of code added 24 September 2005



    # this mails the error to rob
    my $mail_prog = "/usr/sbin/sendmail"; # location of sendmail on server;
    unless ($subject =~ m/comment_sender\.pl$/) {    # I changed the name to prevent spam.  Should make this an %ignore_files hash
	open(MAIL,"|$mail_prog -t");
	print MAIL "To: thunderrabbit\@gmail.com\n";
	print MAIL "From: 404bot\@robnugen.com\n";
	print MAIL "Subject: $subject\n\n";
	print MAIL "\n$body";
	print MAIL"\n\n";
	close (MAIL);
    }
}
