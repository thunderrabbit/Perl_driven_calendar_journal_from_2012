#!/usr/bin/perl

require 5.004;
use Socket;
use FileHandle;
#use strict 'vars';
my($eoln)="\n";
my($hostname,$resp);
my($COMICS_COM_URL) = "http://www.comics.com";
my($COMICS_COM_DIR) = "comics/";
my($COMICS_COM_URL_FILLER) = "/archive/";
my($THIS_PL) = "comics.pl";

# ROB added these two lines to make this code work via the browser
print "Content-type: text/html\n\n";

@ARGV = split(/&/, $ENV{"QUERY_STRING"});
my ($arg) = shift(@ARGV);

# if there is no argument at all, show getfuzzy
if (!$arg) {
    # smurf $arg as if we selected getfuzzy so the drop down will indicate such
    $arg='comicURL=%2Fcomics%2Fgetfuzzy%2Findex.html';
}

# if the argument begins with comic= then the rest of the arg is the URL to slurp first
if ($arg =~ m!^comicURL=(.*)!) {
    $url = $1;
    $url =~ s/%([a-fA-F0-9]{2})/chr(hex($1))/ge;

    $opt_url = $COMICS_COM_URL . $url;
}
else {
    $opt_url = $COMICS_COM_URL . "/" . $COMICS_COM_DIR . $arg . "/";
}

print "\n<p><b><a href='$opt_url'>$opt_url</a></b></p>\n";

&slurpURL($opt_url);

&printListOfComics($body);

&printThatDaysComic($body);

&extractURLSFromMainBody($body);

foreach $url (@URLS)
{
    $url = $COMICS_COM_URL . $url;
    &slurpURL($url);
    &printThatDaysComic($body);
}

######################################################################
# subs go here
######################################################################

sub slurpURL {

    ($opt_url) = @_;
    # This regex only works perfectly on fully-specified urls.  See the other
    # usage of this regex below for a fix.

    ($hostname,$file,$suffix) = $opt_url =~ m|^(?:http://)?([^/\#\?]*)([^\#\?]*)(.*)|;

    #println("hostname is: $hostname");
    #println("file is: $file");
    #println("suffix is: $suffix");
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

sub printListOfComics {
    my ($body) = @_;
    my ($first_part,$second_part);

    $body =~ m|(<SELECT\s+.*?</SELECT>)|gs;

    # Note: The [^>]*? could soak up the rest of the url,
    # except that we are given that there is only one occurrence
    # of href outside the url.
	    
    $select = $1;


    print "<p><form method='get' action='$THIS_PL'>";
    print "<select name=comicURL onChange='submit()'>";
    while ($select =~ m!(<OPTION\ VALUE...(comics|wash|creators).*?)(>.*?</OPTION>)!xigs) {
	$first_part = $1;
	$second_part = $3;
	print $first_part;
	if ($1 =~ m!$url!) {
	    print " SELECTED";
	}
	print $second_part;
    }
    print "</select></form></p>";

}


sub printThatDaysComic {
    ($body) = @_;

    while ( $body =~ m|
	    <\s*
	    [Ii][Mm][Gg]\s+
	    [^>]*?                # See note 1 below
	    [Ss][Rr][Cc]\s*
	    =\s*
	    (\"?)                 # the url \"? delimiter
	    ([^\s\"\>]*)          # the url itself
	    \1\s*                 # the delimiter again
	    [^>]*?                # the non-greedy is key
	    [Tt][Oo][Dd][Aa][Yy]
	    [^>]*?                # still non-greedy
	    >
	    # Note 1: The [^>]*? could soak up the rest of the url,
	    # except that we are given that there is only one occurrence
	    # of href outside the url.
	    |xgs ) {
	$new_url = $2;

	print ("<a href='$COMICS_COM_URL$new_url'><img src='$COMICS_COM_URL$new_url'></a>");
    }

}

sub extractURLSFromMainBody {
    ($body) = @_;

    $body =~ m|<a\sname="calendar">(.*?</TABLE>)|gs;
    $table = $1;

    while ($table =~ m|
	    <\s*
	    [Aa]\s+
	    [^>]*?                # See note 1 below
	    [Hh][Rr][Ee][Ff]\s*
	    =\s*
	    (\"?)                 # the url \"? delimiter
	    ([^\s\"\>]*)          # the url itself
	    \1\s*                 # the delimiter again
	    [^>]*?                # the non-greedy is key
	    >
	    # Note 1: The [^>]*? could soak up the rest of the url,
	    # except that we are given that there is only one occurrence
	    # of href outside the url.
	    |xgs ) {
	unshift (@URLS , $2);
    }
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

# Readline('SOCK') -- given a file handle,
# reads and returns a single text line
# with the EOLN char(s) removed. Returns false on EOF.
sub Readline {
    my ($sock) = @_;
    my($line);
    $line = <$sock>;        ## read a single text line
    if (!$line) { return $line; }   ## check if there's nothing (EOF case)
    $line =~ s/[\r\n]//g;   ## delete all the \r \n's

##    print $line, "\n";   ## enable to see all that is received

    return($line);
}


sub println {
	print shift(@_).$eoln;
}

