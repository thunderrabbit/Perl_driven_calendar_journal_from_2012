use Socket;
use FileHandle;

# this was taken from comics.com which was taken from Fred's core URL
# slurper thing.  Now I can just "use" this module each time I
# need the functionality.

# this is being used by top.pl in the index_view directory

my($eoln)="\n";

sub slurpURL {

    ($opt_url) = @_;
    # This regex only works perfectly on fully-specified urls.  See the other
    # usage of this regex below for a fix.

    ($hostname,$file,$suffix) = $opt_url =~ m|^(?:http://)?([^/\#\?]*)([^\#\?]*)(.*)|;

    # println("hostname is: $hostname");
    # println("file is: $file");
    # println("suffix is: $suffix");

    if ( !$file ) { $file = "/"; }

    #make connection
    MakeConnection($hostname,1);

    ######################################################################
    # send get request; process output
    ######################################################################
    if ($suffix =~ m/^\?/) {
	print SOCK "GET $file$suffix HTTP/1.0".$eoln.$eoln;
	#print      "GET $file$suffix HTTP/1.0".$eoln.$eoln;
    } else {
	print SOCK "GET $file HTTP/1.0".$eoln.$eoln;
	#print      "GET $file HTTP/1.0".$eoln.$eoln;
    }

    #get output from web server
    $resp = Slurp(SOCK);       #

    ($header,$body) = split('\n\n',$resp,2);    # separate header from body
    $header=$header."\n\n";

    $header =~ m|^HTTP/[\d\.]*\s((\d*).*)|m;    # ends at newline
    my($HTTPresp)=$1;    #println("HTTPresp: <$HTTPresp>");
    my($HTTPcode)=$2;    #println("HTTPcode: <$HTTPcode>");

    if ($HTTPcode<400 && $HTTPcode>299) {
	#look for location: within response, and print that
	print "ERR $HTTPresp\t";
	if ( $header =~ m|^(Location:.*)|m ) {
	    print $1;
	}
	println("");
	exit(-1);
    } elsif ($HTTPcode!=200) {
	println("ERR $HTTPresp");
	exit(-1);
    }
#    println("OK");
#    $visited{$opt_url} = 1;

}


sub MakeConnection {
	my($port)=80;
	my($hostname,$ip,$sockaddr);
	$hostname=shift(@_);
	$exit_if_error=shift(@_);

	if (!($ip = inet_aton($hostname))) {
		print "ERR Bad host\n";
		exit(-1) if $exit_if_error;
		return 0;
	}
	if ( !($sockaddr = sockaddr_in($port, $ip)) ) {
		print "error socket\n";
		exit(-1) if $exit_if_error;
		return 0;
	}
	if ( !socket(SOCK,PF_INET,SOCK_STREAM,0) ) {
		print "error socket\n";
		exit(-1) if $exit_if_error;
		return 0;
	}
	if ( !connect(SOCK,$sockaddr) ) {
		print "ERR Bad connection\n";
		exit(-1) if $exit_if_error;
		return 0;
	}
	
	autoflush SOCK, 1;
	return 1;
}


sub Slurp {
	my ($sock) = @_;
	undef $/;
	$_ = <$sock>;
	s/\015?\012/\n/g;
	$/="\n";
	return $_;
}

sub println {
	print shift(@_).$eoln;
}

1;
