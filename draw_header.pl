sub draw_header {
    $new_date = $date;  # if $require_reload = 1, then $new_date will be used below to refresh to new URL
    if ($date eq "nil") {
	# this code was jacked from sidebar.pl to force the redirect to happen if the date is not given
	# this code was jacked from sidebar.pl to force the redirect to happen if the date is not given
	# this code was jacked from sidebar.pl to force the redirect to happen if the date is not given
	undef $/;      # file slurp mode
	open LSONER, $indexname;
	$ls1r = <LSONER>;
	$/ = "\n";  # unslurp mode

	# if date does not start with a four digit year, then grab the Latest Date as defined in the ls1R.html file
	($new_date) = $ls1r =~ m/CURRENT ENTRY DATE: (.*)/m;
    }

    print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">\n";
#    print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
#    print "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n";	
    print "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">\n";
    print "<head>\n";
    print "<link rel=\"stylesheet\" type=\"text/css\" href=\"$style\" />\n";

    #### GROSS HACK #### GROSS HACK #### GROSS HACK #### GROSS HACK #### GROSS HACK
    #
    if (($printer_version) && ($journal_type eq "nihongo")) {
	print "<style> p { line-height:300% } </style>\n";
    }
    #
    #### GROSS HACK #### GROSS HACK #### GROSS HACK #### GROSS HACK #### GROSS HACK

    

    print "\n<title>Keep pushing the limits.</title>\n";

    if ($date eq "nil" || $require_reload) {
	# After the header is drawn, journal.pl will die due to "nil" date and this refresh will occur
	print "<meta http-equiv=\"refresh\" content=\"0;url=journal.pl?type=$journal_type&date=$new_date\" />\n";
	print "<script language=Javascript1.0>\n";
	print "window.location.href=\"journal.pl?type=$journal_type&date=$new_date\"\n";
	print "</script>\n";
    }


    # This bit of code might ought to be pulled into its own function in case I want to draw the head charset elsewhere
    # for example, on my resume page, which has these characters as well.
    use DateTime::Format::Strptime;
    my $parser = DateTime::Format::Strptime->new( pattern => '%Y/%m/%d' );
    my $requested_date = $parser->parse_datetime( $new_date );
    my $utf8_began_on_date = $parser->parse_datetime( '2010/05/10' );

    if($requested_date < $utf8_began_on_date || $requested_date == $parser->parse_datetime( '2016/03/24'))
    {
	print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=EUC-JP\" />";
    }
    else
    {
	print "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />";
    }

    # The above code might ought to be pulled into its own function in case I want to draw the head charset elsewhere

    print "</head>\n";
}
1;

