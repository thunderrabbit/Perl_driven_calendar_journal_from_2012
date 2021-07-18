require "single_navigation_bar.pl";

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



    $friendfeedchiclet = '<a href="http://friendfeed.com/thunderrabbit"><img src="http://friendfeed.com/static/images/chiclet.png" alt="Subscribe to me on FriendFeed" title="Subscribe to me on FriendFeed"/></a>';
    $friendfeedwidget = '<script type="text/javascript" src="http://friendfeed.com/embed/status/thunderrabbit?hide_logo=1&amp;hide_comments_likes=1&amp;hide_subscribe=1&amp;width=500"></script><noscript><a href="http://friendfeed.com/thunderrabbit"><img alt="View my FriendFeed" style="border:0;" src="http://friendfeed.com/embed/status/thunderrabbit?hide_logo=1&amp;hide_comments_likes=1&amp;hide_subscribe=1&amp;width=500&amp;format=png"/></a></noscript>';

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
    $html .= <<GOOGLESTUFF;

<!--  begin google-analytics code -->
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript"></script>
<script type="text/javascript">
    _uacct = "UA-163258-1";
    urchinTracker();
</script>
<!--  end google-analytics code -->

<!-- SiteSearch Google >
<form method="get" action='http://www.google.com/custom'>
<table>
<tr><td valign='top' align='center'>
<a href='http://www.google.com/'><img src='http://www.google.com/logos/Logo_25wht.gif' alt='Google' class="nada" /></a>
</td>
<td>
<input type="hidden" name="domains" value="robnugen.com" />
<input type="text" name="q" size="31" maxlength="255" value="" />
<br /><input type="submit" name="sa" value='search' />
<span style="font-size: smaller">
<input type="radio" name="sitesearch" value='' /> Web
<input type="radio" name="sitesearch" value='robnugen.com' checked="checked" /> robnugen.com
</span>

<input type="hidden" name="client" value='pub-8968158139273573' />
<input type="hidden" name="forid" value='1' />
<input type="hidden" name="channel" value='5817411192' />
<input type="hidden" name="ie" value='ISO-8859-1' />
<input type="hidden" name="oe" value='ISO-8859-1' />
<input type="hidden" name="cof" value='GALT:#008000;GL:1;DIV:#336699;VLC:663399;AH:center;BGC:FFFFFF;LBGC:336699;ALC:0000FF;LC:0000FF;T:000000;GFNT:0000FF;GIMP:0000FF;FORID:1;' />
<input type="hidden" name="hl" value='en' />

</td></tr></table>
</form>
< end SiteSearch Google -->
GOOGLESTUFF

    $html .=  "</td><td align='left' valign='top'>";
#    $html .= '<div id="twitter_div">';

    $html .=  "Rob is " . &date_difference("1970/3/25") . " <a href='/cgi-bin/daysold.pl'>days old</a> ";

    $html .= $friendfeedwidget;
# change journal.pl at the bottom as well
#    $html .= <<TWITTER;
# <ul style="list-style-type: none" class="twitter-title" id="twitter_update_list"></ul></div>
# TWITTER
    $html .=  "</td>\n";
    $html .=  "</tr></table>\n";
    $html .= "<!-- end of navigation stuff at top of page -->\n";
    return $html;
}

sub draw_navigation {
    print &draw_AJAX_navigation(@_);
}
1;
