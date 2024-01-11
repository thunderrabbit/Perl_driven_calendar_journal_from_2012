sub single_navigation_bar {

    require "mkdef.pl";
    local ($param_nav_set, $param_item_name) = @_;

    my $html;
    my $nav_settings_file = "/home/dh_r2ixxd/perl.robnugen.com/navigation_definitions.txt";

    open (IN, $nav_settings_file) or die "Can't open " . $nav_settings_file . " for reading";

    while (<IN>) {
	# separate the line using the space character as separator
	($nav_set, $item_name, $on, $off, $url) = split;

	$on =~ s/\+/ /g;   # 2007 aug 2: convert + to spaces, which allows the RSS feeds to have <a href...>
	$off =~ s/\+/ /g;   # 2007 aug 2: convert + to spaces, which allows the RSS feeds to have <a href...>

	if ((mkdef($param_nav_set) eq mkdef($nav_set))) {
	    if ($param_item_name eq $item_name) {
		# check to see if the $on string is an image
		if ($on =~ m/(gif$|jpg$)/) {
		    # yes, then print it as an inline image
		    $html .= "<img src='$on'>\n";
		}
		else
		{
		    $html .= "$on\n";
		}
	    } else {
		# check to see if the $off string is an image
		if ($off =~ m/(gif$|jpg$)/) {
		    # yes, then print it as an inline image
		    $html .= "<a href=\"$url\"><img src='$off'></a>\n";
		} else {
		    $html .= "<a href=\"$url\">$off</a>\n";
		}
	    }
	}   # ($param_nav_set eq $nav_set)
    }
    close IN or die "Can't close " . $nav_settings_file;
    return $html;
}
1;
