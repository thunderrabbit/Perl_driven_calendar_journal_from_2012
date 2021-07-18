#  	if ($name_param = $query->param('name')) {
#	    $cookie{'name'} = $name_param;
#       }

sub setCookies {
    my $cookiedough = "Setting cookies: ";
    my (%cookie) = @_;
    my ($local_cookie, $key, $expiration);
    foreach $key (keys %cookie) {
	$expiration = $cookie{$key} eq "deleted" ? "-3M" : "+12M";
	$local_cookie = new CGI::Cookie(-name    =>  "$key",
					-value   =>  "$cookie{$key}",
					-expires =>  "$expiration",
					-domain  =>  $ENV{'HTTP_HOST'},   # change from SERVER_NAME after I made www.robnugen.com -> robnugen.com
					-path    =>  '/',
					-secure  =>  0
					);
	print "Set-Cookie: $local_cookie\n";
	$cookiedough .= "<br>" . "$local_cookie";
    }

    # this is being added 2005 Feb to see what value is being set
    $cookiedough;
}
1;
