#!/usr/bin/perl

##  From: Fred Nugen <nooj@mail.ma.utexas.edu>
##  Date: Sat Feb 22, 2003  11:25:17 Asia/Tokyo
##  To: ss@robnugen.com
##  Subject: site sucker: a basic http request script
##  
##  Note that these techniques are 1) better done with CGI.pm, and
##  2) somewhat outdated, as almost all web servers now use HTTP 1.1.
##  The program still works since they still support 1.0 requests.  
##  
##  Anyway, this program makes a HTTP 1.0 request, scans the response, and
##  looks for links within it.  Each link found is requested--dead links
##  are reported as dead, valid links are reported as ok.  
##  Usage:  ss.pl (-a | -h | -b | -x | -c) [-f string] URL
##   -h  display header only for initial request (for debugging)
##   -b  display body only for initial request (for debugging)
##   -a  display all of initial response (both header and body) (for debugging)
##   -x  extract URLs, do not check
##   -c  extract URLs, check
##   -f  optional regex filter on URLs for -x and -c options
##  
##  This program is the basis of all my perl programs 
##  that make HTTP requests.

require 5.004;
use Socket;
use FileHandle;
#use strict 'vars';
my($eoln)="\n";
my($hostname,$resp);

## Values from the command line...
my($opt_url, $opt_h, $opt_b, $opt_a, $opt_x, $opt_c, $opt_f);

$opt_url = "";  ## the url
$opt_h = 0;  ## head only
$opt_b = 0;  ## body only
$opt_a = 0;  ## all
$opt_x = 0;  ## extract URLs
$opt_c = 0;  ## check the extracted URLs
$opt_f = ""; ## optional "filter" string for -x and -c

# ROB added these two lines to make this code work via the browser
print "Content-type: text/html\n\n";
@ARGV = split(/&/, $ENV{"QUERY_STRING"});

## Code set the opt_* variables from the command line
while (@ARGV) {
    my ($arg) = shift(@ARGV);
    print "<br>\$arg is $arg\n";
    if (!@ARGV) {	$opt_url = $arg; }
    elsif (lc($arg) eq "-f") { $opt_f = shift(@ARGV); }
    elsif (lc($arg) eq "-h") { $opt_h = 1; }
    elsif (lc($arg) eq "-b") { $opt_b = 1; }
    elsif (lc($arg) eq "-a") { $opt_a = 1; }
    elsif (lc($arg) eq "-x") { $opt_x = 1; }
    elsif (lc($arg) eq "-c") { $opt_c = 1; }
}

if (!($opt_url && ($opt_a || $opt_b || $opt_h || $opt_x || $opt_c))) {
    print "\n<p>Usage: one of (-a -h -b -x -c), optional -f string, URL\n";
    die "Usage: one of (-a -h -b -x -c), optional -f string, URL";
}

print "$opt_url\t";

#This regex only works perfectly on fully-specified urls.  See the other
#usage of this regex below for a fix.
($hostname,$file,$suffix) =
	$opt_url =~ m|^(?:http://)?([^/\#\?]*)([^\#\?]*)(.*)|;
#println("hostname is: $hostname");
#println("file is: $file");
#println("suffix is: $suffix");
if ( !$file ) { $file = "/"; }

#make connection
MakeConnection($hostname,1);

######################################################################
#send get request; process output
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
println("OK");
$visited{$opt_url} = 1;

if ($opt_a) {print $resp;}
if ($opt_h) {print $header;}
if ($opt_b) {print $body;}

if ($opt_x || $opt_c) {        #do common stuff here, specific stuff after
	($path) = $file =~ m|^(.*/)[^/]*$|;
	#println("file: $file");
	#println("path: $path");

	# get urls from body; attach scheme, host, and/or path as appropriate
	while ( $body =~ m|
					           <\s*
					           [Aa]\s+
					           [^>]*?                # See note 1 below
					           [Hh][Rr][Ee][Ff]\s*   #
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
		$new_url = $2;
		#println();
		#println("\$new_url: $new_url");
		$new_url =~ m|^(?:(\w+:(?://)?)([^/\#\?]*))?([^\#\?]*)(.*)|;
		#println("s<$1> h<$2> f<$3> s<$4>");
		($new_scheme,$new_hostname,$new_file,$new_suffix) = ($1,$2,$3,$4);
		#$blah = join '*', $new_scheme,$new_hostname,$new_file,$new_suffix;
		#println($new_url);
		#println($blah);
		if ( !$new_scheme ) { $new_scheme="http://"; }
		if ( $new_scheme eq "http://" && !$new_hostname ) {
			$new_hostname=$hostname;
		}
		if ( $new_scheme eq "http://" && !$new_file ) {
			#then probably there was no hostname, and the file is in $new_hostname
			$new_file = $new_hostname;
			$new_hostname = $hostname;
		}
		if ( $new_scheme eq "http://" && !($new_file =~ m|^/|) ) {
			#no leading slash, must be a relative url, prepend path
			$new_file = $path.$new_file;
		}
		$new_url = $new_scheme.$new_hostname.$new_file.$new_suffix;
		#println("final url: $new_url");

		if ($opt_f && !($new_url =~ m|$opt_f|i)) {
			#println("-f match failed");
			next;
		}


		######################################################################
		# $opt_x specific stuff
		######################################################################
		if ( $opt_x ) {
			println($new_url);
		}

		######################################################################
		# $opt_c specific stuff
		######################################################################
		if ( $opt_c ) {
			print "$new_url\t";
			if ( $new_scheme ne "http://" ) {
				println("STOP not HTTP");
				next;
			}

			#print %visited;
			#println();

			if ( defined( $visited{$new_url} ) ) {
				println("STOP Visited");
				next;
			}
			$visited{$new_url} = 1;

			#make connection
			if ( !(MakeConnection($new_hostname,0)) ) {
				#println("connection failed; go to next url");
				next;
			}

			#send head request; process output
			if ($suffix =~ m/^\?/) {
				print SOCK "HEAD $new_file$new_suffix HTTP/1.0".$eoln.$eoln;
				#print      "HEAD $new_file$new_suffix HTTP/1.0".$eoln.$eoln;
			} else {
				print SOCK "HEAD $new_file HTTP/1.0".$eoln.$eoln;
				#print      "HEAD $new_file HTTP/1.0".$eoln.$eoln;
			}

			#get output from web server
			$new_header = Slurp(SOCK);

			$new_header =~ m|^HTTP/[\d\.]*\s((\d*).*)|m;    # ends at newline
			my($new_HTTPresp)=$1;    #println("new_HTTPresp: <$new_HTTPresp>");
			my($new_HTTPcode)=$2;    #println("new_HTTPcode: <$new_HTTPcode>");

			if ($new_HTTPcode<400 && $new_HTTPcode>299) {
				#look for location: within response, and print that
				print "ERR $new_HTTPresp\t";
				if ( $new_header =~ m|^(Location:.*)|m ) {
					print $1;
				}
				println("");
				next;
			} elsif ($new_HTTPcode!=200) {
				println("ERR $new_HTTPresp");
				next;
			}
			println("OK");
		}
	}
}



######################################################################
# subs go here
######################################################################

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

