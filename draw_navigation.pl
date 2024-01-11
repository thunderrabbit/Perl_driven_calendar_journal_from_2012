require "single_navigation_bar.pl";

use Cwd qw( abs_path );     # allows Perl 5.26 to include local module date_smurfer.pm
use File::Basename qw( dirname );
use lib dirname(abs_path(__FILE__));

sub draw_AJAX_navigation {

    # Parameters are sent as a &-delimited string like
    # 0main&1yruu&2sf&basics

    # This string will be sent two pieces at a time to draw a single
    # navigation bar at a time. Sending 0main and 1yruu means draw the
    # main navigation bar and highlight the yruu item.

    # next send 1yruu and 2sf so we print the yruu bar and highlight
    # sf.

    # this allows any number of navigation bars to be displayed easily

    use date_smurfer;
    # grab parameters
    @param_nav_set = split(/&/, $_[0]);
#    warn "|" . join (", ", @param_nav_set) . "|\n";

    my $html = "";
    $html .= "<table border=\"0\" width=\"100%\"><tr><td valign=\"top\">\n";
    for (local $p_count = 0; $p_count < @param_nav_set-1; $p_count++) {
	$html .= &single_navigation_bar ($param_nav_set[$p_count],$param_nav_set[$p_count+1]);
	$html .= "<br />";
    }
    $html .= "</td><td valign=\"top\">";

    $html .=  "</td><td align='left' valign='top'>";

    $html .=  "Rob is " . &date_difference("1970/3/25") . " <a href='/cgi-bin/daysold.pl'>days old</a> ";

# change journal.pl at the bottom as well
    $html .=  "</td>\n";
    $html .=  "</tr></table>\n";
    $html .= "<!-- end of navigation stuff at top of page -->\n";
    return $html;
}

sub draw_navigation {
    print &draw_AJAX_navigation(@_);
}
1;
