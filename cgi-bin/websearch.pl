#!/usr/local/bin/perl

############################################
##                                        ##
##               WebSearch                ##
##           by Darryl Burgdorf           ##
##       (e-mail burgdorf@awsd.com)       ##
##                                        ##
##             version:  2.11             ##
##        last modified:  08/27/02        ##
##           copyright (c) 2002           ##
##                                        ##
##    latest version is available from    ##
##        http://awsd.com/scripts/        ##
##                                        ##
############################################

# COPYRIGHT NOTICE:
#
# Copyright 2002 Darryl C. Burgdorf.  All Rights Reserved.
#
# This program is being distributed as shareware.  It may be used and
# modified by anyone, so long as this copyright notice and the header
# above remain intact, but any usage should be registered.  (See the
# program documentation for registration information.)  Selling the
# code for this program without prior written consent is expressly
# forbidden.  Obtain permission before redistributing this program
# over the Internet or in any other medium.  In all cases copyright
# and header must remain intact.
#
# Certain subroutines and code segments utilized in this program are
# adapted from code written by Kevin Dearing of webjourneymen.net
# and dacpro.com, and are used with permission.
#
# This program is distributed "as is" and without warranty of any
# kind, either express or implied.  (Some states do not allow the
# limitation or exclusion of liability for incidental or consequential
# damages, so this notice may not apply to you.)  In no event shall
# the liability of Darryl C. Burgdorf and/or Affordable Web Space
# Design for any damages, losses and/or causes of action exceed the
# total amount paid by the user for this software.

# VERSION HISTORY:
# <snip>

##################################
# DEFINE THE FOLLOWING VARIABLES #
##################################

require "draw_navigation.pl";

# WAS: @dirs = ('/usr/www/foo/scripts/dir1/','/usr/www/foo/scripts/dir2/*');
@dirs = ('/home/barefoot_rob/temp.robnugen.com/journal/*+');

$DEBUG = 0;

%webbbs4_dirs = ();

$ListExcludedFiles = 0;

$DBMType = 0;

$searchindex = "";

# WAS: $avoid = '(\.backup|\.cgi|\.pl|\.txt)';
# explicitly avoid DD/_, files that end with ".comment" and files that don't have DDDD/DD/DD in them.

# files must avoid this pattern
$avoid = '(\d\d\/_|\.comment$)';

# files must match this pattern
$match = '\d\d\d\d\/\d\d\/\d\d';

# WAS: $cgiurl = 'http://www.foo.com/cgi-bin/websearch.pl';
$cgiurl = 'http://robnugen.com/cgi-bin/websearch.pl';

###  # WAS: $basepath = '/usr/www/foo/scripts/';
###  # WAS: $baseurl = 'http://www.foo.com/scripts/';
###  
###  # In the code below, I replaced all (seven) occurrences of $basepath and $baseurl with the
###  # values below (minus '(.*)' in 2 cases).  The tokens were being evaluated in ways I didn't like and couldn't seem to 
###  # control with single or double quotes, etc.   So I just replaced them overtly.
###  
###  $basepath = "/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)";
###  $baseurl = 'http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3';

# %otherurls = (
#   '/usr/www/foo/scripts/dir2/sub1/',
#   'http://www.foo.com/cgi-bin/some.cgi?access=',
#   '/usr/www/foo/scripts/dir2/sub2/',
#   'http://www.foo.com/scripts/dir2/sub2/another.cgi?read='
#   );

$AllowDateSearch = 1;
$DisplayByDate = 0;

%extrachars = ();

$NoMETAs = 0;
$METAsOnly = 0;

$UseDescs = 1;
$DescLength = 500;

$SplitNames = 0;

$bodyspec = "BGCOLOR=\"#ffffff\" TEXT=\"#000000\"";
$meta_file = "";
$header_file = "";
# 2006 may 22 (can't find header.txt, probably since I moved from shell1) $header_file = "/home/barefoot_rob/temp.robnugen.com/journal/search/header.txt";
# $footer_file = "/usr/www/foo/footer.txt";

undef $keyword_log_file;

$PrintNewForm = 1;
$FormExplanation = "The search terms you input do not have to be complete words. <BR>&quot;Wash,&quot; for example, will match occurrences of wash, washer, Washington, etc. <BR>Do not include asterisks or other non-alphanumeric characters in your search terms <BR>unless you actually want them included (as with &quot;C++&quot;) as part of your search.";

$HourOffset = 0;

###################################
# CHANGE NOTHING BELOW THIS LINE! #
###################################

$version = "2.11";

use Fcntl;
BEGIN { @AnyDBM_File::ISA = qw (DB_File GDBM_File SDBM_File ODBM_File NDBM_File) }
use AnyDBM_File;
umask (0111);
require "find.pl";

$time = time;

@day = ('Sun','Mon','Tue','Wed','Thu','Fri','Sat');
@month = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');

($SSIvirtual,$SSIfile,$PseudoQS) = (&FindSpecifics);

if ($ENV{'CONTENT_LENGTH'}) {
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
	@pairs = split(/&/, $buffer);
	foreach $pair (@pairs){
		($name, $value) = split(/=/, $pair);
		$name =~ tr/+/ /;
		$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		if ($FORM{$name}) { $FORM{$name} = "$FORM{$name}, $value"; }
		else { $FORM{$name} = $value; }
	}
}
elsif ($ENV{'QUERY_STRING'} =~ /terms=([^\s&;\?]*)/i) {
	$FORM{'terms'} = $1;
	$FORM{'terms'} =~ s/\+/ /g;
	if ($ENV{'QUERY_STRING'} =~ /boolean=all/i) {
		$FORM{'boolean'} = "all terms";
	}
}
else {
	$ListOnly = 1;
}

if (%webbbs4_dirs || $searchindex) {
	$DisplayByDate = 1;
	$FORM{'case'} = "insensitive";
	if ($FORM{'boolean'} eq 'as a phrase') {
		$FORM{'boolean'} = "all terms";
	}
}

unless ($FORM{'boolean'}) { $FORM{'boolean'} = "any terms"; }
unless ($FORM{'case'}) { $FORM{'case'} = "insensitive"; }
unless ($FORM{'hits'}) { $FORM{'hits'} = 25; }
unless ($FORM{'terms'}) { $NoTerms = 1; }

if ($FORM{'terms'} && $keyword_log_file) {
	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	if ($year>100) { $year -= 100; }
	$mon++;
	if ($year<10) { $year = "0".$year; }
	if ($mon<10) { $mon = "0".$mon; }
	if ($mday<10) { $mday = "0".$mday; }
	if ($hour<10) { $hour = "0".$hour; }
	if ($min<10) { $min = "0".$min; }
	open (KEYWORDLOG,">>$keyword_log_file");
	print KEYWORDLOG "$mon/$mday/$year $hour:$min - ",
	  "$FORM{'boolean'} & $FORM{'case'} - $FORM{'terms'}\n";
	close (KEYWORDLOG);
}

$matchstring = "\\w\\.\\-\\'";
foreach $extrachar (keys %extrachars) {
	$matchstring .= "\\$extrachars{$extrachar}";
}

if ($FORM{'case'} eq "insensitive") {
	foreach $extrachar (keys %extrachars) {
		unless ($extrachar eq $extrachars{$extrachar}) {
			$FORM{'terms'} =~ s/$extrachars{$extrachar}/$extrachar/g;
		}
	}
	$FORM{'terms'} =~ tr/A-Z/a-z/;
	foreach $extrachar (keys %extrachars) {
		unless ($extrachar eq $extrachars{$extrachar}) {
			$FORM{'terms'} =~ s/$extrachar/$extrachars{$extrachar}/g;
		}
	}
}
$FORM{'terms'} =~ s/\s+/ /g;
$FORM{'terms'} =~ s/^\s//;
$FORM{'terms'} =~ s/\s$//;
$FORM{'terms'} =~ s/[^$matchstring]/ /g;
$FORM{'terms'} =~ s/([^\w\s])/\\$1/g;

if ($FORM{'boolean'} eq "as a phrase") { push (@terms,$FORM{'terms'}); }
else { @terms = split(/\s+/,$FORM{'terms'}); }

$matchcount=$filecount=$avoidedfilecount=0;

unless ($searchindex && !($ListOnly)) {
	foreach $file (@dirs) {
		undef (@AllFiles);
		undef ($AllText);
		if ($file =~ s/\+$//) {
			$AllText = 1;
		}
		if ($file =~ s/\*$//) {
			$AllDirs = 1;
			&find ($file);
		}
		else {
			opendir(DIR,$file);
			@AllFiles = readdir(DIR);
			closedir(DIR);
		}
		$file =~ s/\/$//;
		foreach $subfile (@AllFiles) {
			unless ($subfile =~ /^$file/) {
				$subfile = $file."/".$subfile;
			}
			if ($ListOnly) {
				$subfiledir = $subfile;
				$subfiledir =~ s/\/[^\/]*$/\//;
				if ($AllText) { $includedAlldirs{$subfiledir} ++; }
				else { $includedHTMLdirs{$subfiledir} ++; }
			}
			if ((-T "$subfile")
			  && ($AllText || ($subfile =~ /\.(s|p)*htm(l)*$/i))
			  && (!$avoid || ($subfile !~ /$avoid/)) 
			  && (!$match || ($subfile =~ /$match/))) {
				$kbytesize{$subfile} = int((((stat($subfile))[7])/1024)+.5);
				$kbytestotal += $kbytesize{$subfile};
				push (@files,"$subfile");
			}
			elsif ($ListOnly && (-T "$subfile")) {
				push (@avoidedfiles,"$subfile");
			}
		}
	}
}

print "Content-type: text/html\n\n";

if ($ListOnly) {
	if ($searchindex) {
		unlink "$searchindex";
		open (SEARCH,">$searchindex") || &Error_SearchIndex;
	}
	&Header("File List");
	print "<PRE>\n";
	foreach $key (keys %includedAlldirs) {
		push (@includedAlldirs,"$key");
	}
	foreach $key (keys %includedHTMLdirs) {
		push (@includedHTMLdirs,"$key");
	}
	@HTMLDIRS = sort (@includedHTMLdirs);
	@ALLDIRS = sort (@includedAlldirs);
	@FILES = sort (@files);
	@AVOIDEDFILES = sort (@avoidedfiles);
	if ($ListExcludedFiles) {
		print "\n---------------------------------------------\n";
		print "The following directories are to be searched:\n";
		print "---------------------------------------------\n\n";
		print "For HTML files only:\n\n";
		unless (@HTMLDIRS) { print "No directories!\n"; }
		foreach $INCLUDEDDIR (@HTMLDIRS) {
			if (%otherurls) {
				foreach $path (keys %otherurls) {
					$INCLUDEDDIR =~ s/$path/$otherurls{$path}/i;
				}
			}
			$INCLUDEDDIR =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
			print "$INCLUDEDDIR\n";
		}
		print "\nFor all text files:\n\n";
		unless (@ALLDIRS) { print "No directories!\n"; }
		foreach $INCLUDEDDIR (@ALLDIRS) {
			if (%otherurls) {
				foreach $path (keys %otherurls) {
					$INCLUDEDDIR =~ s/$path/$otherurls{$path}/i;
				}
			}
			$INCLUDEDDIR =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
			print "$INCLUDEDDIR\n";
		}
	}
	print "\n-----------------------------------------------\n";
	print "The following files are included in the search:\n";
	print "-----------------------------------------------\n\n";
	foreach $FILE (@FILES) {
		if ($searchindex) {
			undef $string;
			$title=$poster=$description="";
			open (FILE,"$FILE");
			@LINES = <FILE>;
			close (FILE);
			$mtime = (stat($FILE))[9];
			$kbytesize = int((((stat($FILE))[7])/1024)+.5);
			$string = join(' ',@LINES);
			undef @LINES;
			$string =~ s/\n/ /g;
			$string =~ s/<SCRIPT.*?<\/SCRIPT>/ /gi;
			$string =~ s/<!--\s*robots*\s+content\s*=\s*"?(none|noindex)"?\s*-->.*?<!--\s*\/robots*\s*-->/ /isg;
			$string =~ s/&nbsp;/ /gi;
			if ($string =~ /<TITLE>([^>]+)<\/TITLE>/i) {
				$title = "$1";
			}
			elsif ($string =~ /SUBJECT>(.+)POSTER>(.+)EMAIL>/i) {
				$title = "$1";
				$poster = "$2";
			}
			elsif ($string =~ /SUBJECT>(.+)POSTER>(.+)DATE>/i) {
				$title = "$1";
				$poster = "$2";
			}
			else {
				$title = "$FILE";
			}
			$string =~ s/^.*<!--websearch-->/ /gi;
			$string =~ s/<!--\/websearch-->.*$/ /gi;
			if ($SplitNames) {
				@names = split (/<\s*A\s*NAME\s*=\s*"*/i,$string);
			}
			else {
				$names[0] = $string;
			}
			$namescount = @names;
			foreach $key (0..$namescount-1) {
				unless ($key==0) {
					$filename = $names[$key];
					$filename =~ s/^([^">]*).*/#$1/;
					$names[$key] =~ s/^[^">]*"*\s*>(.*)/$1/;
					$filename = "$FILE"."$filename";
				}
				else {
					$filename = $FILE;
				}
				$string = $names[$key];
				unless (!($UseDescs) || ($NoMETAs > 0)) {
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*description[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description = "$1";
					}
				}
				$title =~ s/\s+/ /g;
				$title =~ s/^\s*//;
				$title =~ s/\s*$//;
				$title =~ s/"/&quot;/;
				if ($METAsOnly) {
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*description[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description1 = "$1";
					}
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*keywords[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description2 = "$1";
					}
					$string = $title . " " . $description1 . " " . $description2;
				}
				if ($poster) {
					$poster =~ s/\s+/ /g;
					$poster =~ s/^\s*//;
					$poster =~ s/\s*$//;
					$poster =~ s/"/&quot;/;
				}
				$string =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
				unless ($NoMETAs > 0) {
					$string =~ s/<[^>]*META[^>]+NAME\s*=[ "]*(description|keywords)[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/$2/ig;
				}
				unless (!($UseDescs) || ($description)) {
					$description = $string;
					if ($description =~ /<BODY/) {
						$description =~ s/.*<BODY[^>]*>(.*)/$1/i;
					}
					elsif ($description =~ /NEXT>/) {
						$description =~ s/.*NEXT>[^ ]*(.*)/$1/i;
						$description =~ s/.*LINKURL>[^ ]*(.*)/$1/i;
					}
					$description =~ s/<([^>])*>//g;
					$description =~ s/\s+/ /g;
					$description =~ s/^\s*//;
					$description =~ s/\s*$//;
					$description =~ s/"/&quot;/;
					$description = substr($description,0,$DescLength);
				}
				$string =~ s/<([^>])*>//g;
				foreach $extrachar (keys %extrachars) {
					unless ($extrachar eq $extrachars{$extrachar}) {
						$string =~ s/$extrachars{$extrachar}/$extrachar/g;
					}
				}
				$string =~ tr/A-Z/a-z/;
				foreach $extrachar (keys %extrachars) {
					unless ($extrachar eq $extrachars{$extrachar}) {
						$string =~ s/$extrachar/$extrachars{$extrachar}/g;
					}
				}
				$string =~ s/&[^;\s]*;/ /g;
				$string =~ s/[^$matchstring]/ /g;
				$string =~ s/(\s)+/ /g;
				%wordlist = ();
				print SEARCH "$filename \"$title\" \"$poster\" \"$description\" $mtime $kbytesize ";
				@words = split (/\s/,$string);
				foreach $word (@words) {
					next if ($wordlist{$word});
					$wordlist{$word} = 1;
					print SEARCH "$word ";
				}
				print SEARCH "\n";
			}
		}
		if (%otherurls) {
			foreach $path (keys %otherurls) {
				$FILE =~ s/$path/$otherurls{$path}/i;
			}
		}
		$FILE =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
		print "$FILE\n";
		$filecount++;
	}
	print "\nTotal:  ",&commas($filecount)," files\n";
	print "        ",&commas($kbytestotal)," kb\n";
	if ($searchindex) {
		close (SEARCH,">$searchindex");
		print "\nSearch index file successfully created.\n";
	}
	if (%webbbs4_dirs) {
		print "\n------------------------------------------------------------\n";
		print "The following WebBBS 4.XX forums are included in the search:\n";
		print "------------------------------------------------------------\n\n";
		foreach $key (keys %webbbs4_dirs) {
			if ($DBMType==1) {
				tie (%MessageList,'AnyDBM_File',"$key/messagelist",O_RD,0666,$DB_HASH);
			}
			elsif ($DBMType==2) {
				dbmopen(%MessageList,"$key/messagelist",0666);
			}
			else {
				tie (%MessageList,'AnyDBM_File',"$key/messagelist",O_RD,0666);
			}
			@messages = (keys %MessageList);
			$TotalMessages = @messages;
			print "$webbbs4_dirs{$key} (",&commas($TotalMessages)," messages)\n";
			if ($DBMType==2) { dbmclose (%MessageList); }
			else { untie %MessageList; }
		}
	}
	if ($ListExcludedFiles) {
		print "\n-----------------------------------------------------------\n";
		print "The following files are expicitly excluded from the search:\n";
		print "-----------------------------------------------------------\n\n";
		foreach $AVOIDEDFILE (@AVOIDEDFILES) {
			if (%otherurls) {
				foreach $path (keys %otherurls) {
					$AVOIDEDFILE =~ s/$path/$otherurls{$path}/i;
				}
			}
			$AVOIDEDFILE =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
			print "$AVOIDEDFILE\n";
			$avoidedfilecount++;
		}
		print "\nTotal:  ",&commas($avoidedfilecount)," files\n";
	}
	print "\n</PRE>\n";
	&PrintForm;
	&Footer;
	exit;
}

if ($AllowDateSearch && ($FORM{'DateRange'} eq "Range")) {
	unless ($FORM{'StartDateA'}) { $FORM{'StartDateA'} = 1; }
	unless ($FORM{'EndDateA'}) { $FORM{'EndDateA'} = 15; }
	if ($FORM{'StartDateC'} < 1990) { $FORM{'StartDateC'} = 1990; }
	if ($FORM{'EndDateC'} < $FORM{'StartDateC'}) { $FORM{'EndDateC'} = $FORM{'StartDateC'}; }
	$searchrange = "Files posted or updated between $FORM{'StartDateA'} $month[$FORM{'StartDateB'}] ";
	$searchrange .= "$FORM{'StartDateC'} and $FORM{'EndDateA'} ";
	$searchrange .= "$month[$FORM{'EndDateB'}] $FORM{'EndDateC'}";
	$startday = &rangedate($FORM{'StartDateB'}+1,$FORM{'StartDateA'},$FORM{'StartDateC'}-1900);
	$endday = &rangedate($FORM{'EndDateB'}+1,$FORM{'EndDateA'}+1,$FORM{'EndDateC'}-1900);
}
else {
	$startday = 0;
	$endday = 9999999999;
}

unless ($NoTerms) {
	if ($searchindex) {
		open (SEARCH,"$searchindex");
		while (<SEARCH>) {
			if (/^(\S+) "(.*)" "(.*)" "(.*)" (\d+) (\d+) (.*)/) {
				$FILE = $1;
				$title{$FILE} = $2;
				$poster{$FILE} = $3;
				$description{$FILE} = $4;
				$mtime = $mtime{$FILE} = $5;
				$kbytesize{$FILE} = $6;
				$string = $7;
				$filecount++;
				if (($mtime >= $startday) && ($mtime <= $endday)) {
					$value = 0;
					$resetstring = $string;
					if ($FORM{'boolean'} eq 'all terms') {
						foreach $term (@terms) {
							$string = $resetstring;
							$test = ($string =~ s/$term//ig);
							if ($test < 1) {
								$value = 0;
								last;
							}
							else {
								$value = $value+$test;
							}
						}
					}
					else {
						foreach $term (@terms) {
							$string = $resetstring;
							$test = ($string =~ s/$term//ig);
							$value = $value+$test;
						}
					}
					if ($value > 0) {
						$matchcount++;
						$update{$FILE} = &Get_Date;
						$truval{$FILE} = 1;
					}
				}
			}
		}
		close (SEARCH);
	}
	else {
		foreach $FILE (@files) {
			undef $string;
			open (FILE,"$FILE");
			@LINES = <FILE>;
			close (FILE);
			$filecount++;
			$mtime = $mtime{$FILE} = (stat($FILE))[9];
			next unless (($mtime >= $startday) && ($mtime <= $endday));
			$update{$FILE} = &Get_Date;
			$string = join(' ',@LINES);
			undef @LINES;
			$string =~ s/\n/ /g;
			$string =~ s/<SCRIPT.*?<\/SCRIPT>/ /gi;
			$string =~ s/<!--\s*robots*\s+content\s*=\s*"?(none|noindex)"?\s*-->.*?<!--\s*\/robots*\s*-->/ /isg;
			$string =~ s/&nbsp;/ /gi;
			if ($string =~ /<TITLE>([^>]+)<\/TITLE>/i) {
				$title{$FILE} = "$1";
			}
			elsif ($string =~ /SUBJECT>(.+)POSTER>(.+)EMAIL>/i) {
				$title{$FILE} = "$1";
				$poster{$FILE} = "$2";
			}
			elsif ($string =~ /SUBJECT>(.+)POSTER>(.+)DATE>/i) {
				$title = "$1";
				$poster = "$2";
			}
			else {
				$title{$FILE} = "$FILE";
			}
			$string =~ s/^.*<!--websearch-->/ /gi;
			$string =~ s/<!--\/websearch-->.*$/ /gi;
			if ($SplitNames) {
				@names = split (/<\s*A\s*NAME\s*=\s*"*/i,$string);
			}
			else {
				$names[0] = $string;
			}
			$namescount = @names;
			foreach $key (0..$namescount-1) {
				unless ($key==0) {
					$filename = $names[$key];
					$filename =~ s/^([^">]*).*/#$1/;
					$names[$key] =~ s/^[^">]*"*\s*>(.*)/$1/;
					$filename = "$FILE"."$filename";
				}
				else {
					$filename = $FILE;
				}
				$kbytesize{$filename} = $kbytesize{$FILE};
				$mtime{$filename} = $mtime{$FILE};
				$update{$filename} = $update{$FILE};
				$title{$filename} = $title{$FILE};
				$poster{$filename} = $poster{$FILE};
				$val{$filename} = 0;
				$string = $names[$key];
				unless (!($UseDescs) || ($NoMETAs > 0)) {
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*description[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description{$filename} = "$1";
					}
				}
				$title{$filename} =~ s/\s+/ /g;
				$title{$filename} =~ s/^\s*//;
				$title{$filename} =~ s/\s*$//;
				if ($METAsOnly) {
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*description[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description1{$filename} = "$1";
					}
					if ($string =~ /<[^>]*META[^>]+NAME\s*=[ "]*keywords[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/i) {
						$description2{$filename} = "$1";
					}
					$string = $title{$filename} . " " . $description1{$filename} . " " . $description2{$filename};
				}
				if ($poster{$filename}) {
					$poster{$filename} =~ s/\s+/ /g;
					$poster{$filename} =~ s/^\s*//;
					$poster{$filename} =~ s/\s*$//;
				}
				$string =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
				unless ($NoMETAs > 0) {
					$string =~ s/<[^>]*META[^>]+NAME\s*=[ "]*(description|keywords)[ "]+CONTENT\s*=\s*"(([^>"])*)"[^>]*>/$2/ig;
				}
				unless (!($UseDescs) || ($description{$filename})) {
					$description = $string;
					if ($description =~ /<BODY/) {
						$description =~ s/.*<BODY[^>]*>(.*)/$1/i;
					}
					elsif ($description =~ /NEXT>/) {
						$description =~ s/.*NEXT>[^ ]*(.*)/$1/i;
						$description =~ s/.*LINKURL>[^ ]*(.*)/$1/i;
					}
					$description =~ s/<([^>])*>//g;
					$description =~ s/\s+/ /g;
					$description =~ s/^\s*//;
					$description =~ s/\s*$//;
					$description{$filename} = substr($description,0,$DescLength);
					undef $description;
				}
				$string =~ s/<([^>])*>//g;
				if ($FORM{'case'} eq "insensitive") {
					foreach $extrachar (keys %extrachars) {
						unless ($extrachar eq $extrachars{$extrachar}) {
							$string =~ s/$extrachars{$extrachar}/$extrachar/g;
						}
					}
					$string =~ tr/A-Z/a-z/;
				}
				foreach $extrachar (keys %extrachars) {
					unless ($extrachar eq $extrachars{$extrachar}) {
						$string =~ s/$extrachar/$extrachars{$extrachar}/g;
					}
				}
				$string =~ s/&[^;\s]*;/ /g;
				$string =~ s/[^$matchstring]/ /g;
				$string =~ s/(\s)+/ /g;
				$resetstring = $string;
				if ($FORM{'boolean'} eq 'all terms') {
					foreach $term (@terms) {
						$string = $resetstring;
						if ($FORM{'case'} eq 'insensitive') {
							$test = ($string =~ s/$term//ig);
							if ($test < 1) {
								$val{$filename} = 0;
								last;
							}
							else {
								$val{$filename} = $val{$filename}+$test;
							}
						}
						elsif ($FORM{'case'} eq 'sensitive') {
							$test = ($string =~ s/$term//g);
							if ($test < 1) {
								$val{$filename} = 0;
								last;
							}
							else {
								$val{$filename} = $val{$filename}+$test;
							}
						}
					}
				}
				else {
					foreach $term (@terms) {
						$string = $resetstring;
						if ($FORM{'case'} eq 'insensitive') {
							$test = ($string =~ s/$term//ig);
						}
						elsif ($FORM{'case'} eq 'sensitive') {
							$test = ($string =~ s/$term//g);
						}
						$val{$filename} = $val{$filename}+$test;
					}
				}
				if ($val{$filename} > 0) {
					$truval{$filename} = ($val{$filename});
					$matchcount++;
				}
			}
		}
	}
	if (%webbbs4_dirs) {
		foreach $key (keys %webbbs4_dirs) {
			if ($DBMType==1) {
				tie (%MessageList,'AnyDBM_File',"$key/messagelist",O_RD,0666,$DB_HASH);
			}
			elsif ($DBMType==2) {
				dbmopen(%MessageList,"$key/messagelist",0666);
			}
			else {
				tie (%MessageList,'AnyDBM_File',"$key/messagelist",O_RD,0666);
			}
			open (SEARCH,"$key/searchterms.idx");
			while (<SEARCH>) {
				if (/^(\d+) (.*)/) {
					$message = $1;
					$string = $2;
					$filecount++;
					if ((int($MessageList{$message}) >= $startday) && (int($MessageList{$message}) <= $endday)) {
						$value = 0;
						$resetstring = $string;
						if ($FORM{'boolean'} eq 'all terms') {
							foreach $term (@terms) {
								$string = $resetstring;
								$test = ($string =~ s/$term//ig);
								if ($test < 1) {
									$value = 0;
									last;
								}
								else {
									$value = $value+$test;
								}
							}
						}
						else {
							foreach $term (@terms) {
								$string = $resetstring;
								$test = ($string =~ s/$term//ig);
								$value = $value+$test;
							}
						}
						if ($value > 0) {
							$matchcount++;
							$FILE = $webbbs4_dirs{$key}."?review=$message";
							($date,$sub,$poster,$prev,$next,$count,$admin,$ip) =
							  split(/\|/,$MessageList{$message});
							$mtime = $mtime{$FILE} = $date;
							$update{$FILE} = &Get_Date;
							$truval{$FILE} = 1;
							$title{$FILE} = $sub;
							$poster{$FILE} = $poster;
							$title{$FILE} =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
							$poster{$FILE} =~ s/<[^>]*\s+ALT\s*=\s*"(([^>"])*)"[^>]*>/$1/ig;
							$subdir = "bbs".int($message/1000);
							$webbbs4{$FILE} = "$key/$subdir/$message";
						}
					}
				}
			}
			close (SEARCH);
			if ($DBMType==2) { dbmclose (%MessageList); }
			else { untie %MessageList; }
		}
	}
}

foreach $term (@terms) {
	$term =~ s/\\\\/BaCkSlAsH/g;
	$term =~ s/\\//g;
	$term =~ s/BaCkSlAsH/\\/g;
	$term =~ s/&/&amp;/g;
	$term =~ s/"/&quot;/g;
	$term =~ s/>/&gt;/g;
	$term =~ s/</&lt;/g;
}

unless ($FORM{'first'}) { $FORM{'first'} = 1; }
unless ($FORM{'last'}) { $FORM{'last'} = $FORM{'hits'}; }

&NavBar;

&Header("Search Results");

&draw_navigation("0main&1journal&2search");

print "<P ALIGN=CENTER><BIG><BIG><STRONG>Search Results</STRONG></BIG></BIG>\n";
print "<P ALIGN=CENTER>Keywords ($FORM{'boolean'}, ";
print "case $FORM{'case'}): <STRONG>";
if ($NoTerms) { print "No Search Terms Provided!"; }
else { foreach $term (@terms) { print "$term "; } }
print "</STRONG>\n";
if ($searchrange) { print "<BR>$searchrange\n"; }
print "<P ALIGN=CENTER><SMALL>";
print "(<STRONG>",&commas($filecount),"</STRONG> files searched; ";
print "<STRONG>",&commas($matchcount),"</STRONG> match";
if ($matchcount == 1) { print " found)"; }
else { print "es found)"; }
print "</SMALL>\n";

if ($matchcount == 0) {
	print "<P ALIGN=CENTER>No documents matched your search criteria!";
	print "<BR>You might want to revise them and try again.\n";
}
else {
	print $NavBar;
	$Count = 0;
	print "<P><DL>\n";
	if ($DisplayByDate > 0) {
		foreach $key (sort ByDate keys %truval) {
			&PrintEntry;
		}
	}
	else {
		foreach $key (sort ByValue keys %truval) {
			&PrintEntry;
		}
	}
	print "</DL>\n";
	print $NavBar;
}

&PrintForm;
&Footer;
exit;

sub commas {
	local($_)=@_;
	1 while s/(.*\d)(\d\d\d)/$1,$2/;
	$_;
}

sub Get_Date {
	$gd_time = $mtime+($HourOffset*3600);
	($mday,$mon,$yr) = (localtime($gd_time))[3,4,5];
	$yr += 1900;
	$date = "$mday $month[$mon] $yr";
	return $date;
}

sub PrintEntry {
	$Count++;
	next if ($Count < $FORM{'first'});
	last if ($Count > $FORM{'last'});
	if ($webbbs4{$key}) {
		$kbytesize{$key} = int((((stat($webbbs4{$key}))[7])/1024)+.5);
		if ($UseDescs) {
			open (WEBBBS4,"$webbbs4{$key}");
			@message = <WEBBBS4>;
			close (WEBBBS4);
			$description = join(' ',@message);
			$description =~ s/\n/ /g;
			$description =~ s/.*NEXT>[^ ]*(.*)/$1/i;
			$description =~ s/.*LINKURL>[^ ]*(.*)/$1/i;
			$description =~ s/<([^>])*>//g;
			$description =~ s/\s+/ /g;
			$description =~ s/^\s*//;
			$description =~ s/\s*$//;
			$description{$key} = substr($description,0,$DescLength);
		}
	}
	$fileurl = $key;
	if (%otherurls) {
		foreach $path (keys %otherurls) {
			$fileurl =~ s/$path/$otherurls{$path}/i;
			$title{$key} =~ s/$path/$otherurls{$path}/i;
		}
	}
	$DEBUG && print "<br>DEBUG: /home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)";
	$DEBUG && print "<br>DEBUG: http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3";
	$DEBUG && print "<br>DEBUG: $fileurl";
	$fileurl =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
	$DEBUG && print "<br>DEBUG: $fileurl";
	$title{$key} =~ s{/home/barefoot_rob/temp.robnugen.com/journal/(\d\d\d\d)/(\d\d)/(\d\d)(.*)}{http://robnugen.com/cgi-bin/journal.pl?date=$1/$2/$3}i;
	print "<DT>$Count. <STRONG><A HREF=\"$fileurl\">";
	print "$title{$key}</A></STRONG>";
	if ($poster{$key}) { print " (message posted by $poster{$key})"; }
	print "<DD><SMALL>";
	unless ($DisplayByDate > 0) {
		print "Keyword Matches: ";
		print "<STRONG>$truval{$key}</STRONG>; ";
	}
	print "Size: <STRONG>$kbytesize{$key} kb</STRONG>; ";
	if ($poster{$key}) { print "Posted "; }
	else { print "Last updated "; }
	print "<STRONG>$update{$key}</STRONG></SMALL>\n";
	if ($description{$key}) {
		print "<BR><EM>$description{$key}</EM>\n";
	}
	print "<P>\n";
}

sub ByDate {
	$aval = $mtime{$a};
	$bval = $mtime{$b};
	$bval <=> $aval;
}

sub ByValue {
	$aval = $truval{$a};
	$bval = $truval{$b};
	$bval <=> $aval;
}

sub wanted {
	(push (@AllFiles, $name)) && -f $_;
}

sub PrintForm {
	$PrintForm = "<P><CENTER><TABLE BORDER CELLPADDING=12><TR><TD>\n";
	$PrintForm .= "<CENTER><BIG><STRONG>Journal Search</STRONG></BIG>\n";
	$PrintForm .= "<br>(this search is not fast)\n";
	$PrintForm .= "<p><FORM METHOD=POST ACTION=\"$cgiurl\">\n";
	$PrintForm .= "<P><STRONG>Terms for which to search:</STRONG>\n";
	$PrintForm .= "<BR><INPUT TYPE=TEXT NAME=\"terms\" SIZE=60 VALUE=\"";
	foreach $term (@terms) {
		$PrintForm .= "$term ";
	}
	$PrintForm .= "\">\n<P><STRONG>Find:</STRONG> <SELECT NAME=\"boolean\"><OPTION";
	if ($FORM{'boolean'} eq 'any terms') { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">any terms<OPTION";
	if ($FORM{'boolean'} eq 'all terms') { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">all terms";
	unless (%webbbs4_dirs || $searchindex) {
		$PrintForm .= "<OPTION";
		if ($FORM{'boolean'} eq 'as a phrase') { $PrintForm .= " SELECTED"; }
		$PrintForm .= ">as a phrase";
		$PrintForm .= "</SELECT> ";
		$PrintForm .= "<STRONG>Case:</STRONG> <SELECT NAME=\"case\"><OPTION";
		if ($FORM{'case'} eq 'insensitive') { $PrintForm .= " SELECTED"; }
		$PrintForm .= ">insensitive<OPTION";
		if ($FORM{'case'} eq 'sensitive') { $PrintForm .= " SELECTED"; }
		$PrintForm .= ">sensitive";
	}
	$PrintForm .= "</SELECT> ";
	$PrintForm .= "<STRONG>Display:</STRONG> <SELECT NAME=\"hits\"> ";
	$PrintForm .= "<OPTION";
	if ($FORM{'hits'} == 10) { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">10<OPTION";
	if ($FORM{'hits'} == 25) { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">25<OPTION";
	if ($FORM{'hits'} == 50) { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">50<OPTION";
	if ($FORM{'hits'} == 100) { $PrintForm .= " SELECTED"; }
	$PrintForm .= ">100</SELECT> hits per page\n";
	if ($AllowDateSearch) {
		$PrintForm .= "<P><STRONG>Search:</STRONG>\n";
		$PrintForm .= "<BR><INPUT TYPE=RADIO NAME=DateRange VALUE=All";
		unless ($FORM{'DateRange'} eq "Range") {
			$PrintForm .= " CHECKED";
			$mday=$mon="";
		}
		$PrintForm .= "> All files";
		if (($FORM{'DateRange'} eq "Range") && $FORM{'StartDateA'}) {
			$mday = $FORM{'StartDateA'};
			$mon = $FORM{'StartDateB'};
			$year = $FORM{'StartDateC'}-1900;
		}
		else { $year = (localtime($time))[5]; }
		$year+=1900;
		$PrintForm .= "<BR><INPUT TYPE=RADIO NAME=DateRange VALUE=Range";
		if ($FORM{'DateRange'} eq "Range") { $PrintForm .= " CHECKED"; }
		$PrintForm .= "> Files posted or updated between<BR>";
		$PrintForm .= "<FONT FACE=\"Courier\"><INPUT TYPE=TEXT NAME=\"StartDateA\" SIZE=2";
		if ($mday) { $PrintForm .= " VALUE=$mday"; }
		$PrintForm .= "> ";
		$PrintForm .= "<SELECT NAME=\"StartDateB\">";
		foreach $key (0..11) {
			$PrintForm .= "<OPTION VALUE=\"$key\"";
			if ($key == $mon) { $PrintForm .= " SELECTED"; }
			$PrintForm .= ">$month[$key]";
		}
		$PrintForm .= "</SELECT> ";
		$PrintForm .= "<INPUT TYPE=TEXT NAME=\"StartDateC\" SIZE=4 VALUE=$year></FONT>";
		$PrintForm .= " and ";
		if (($FORM{'DateRange'} eq "Range") && $FORM{'EndDateA'}) {
			$mday = $FORM{'EndDateA'};
			$mon = $FORM{'EndDateB'};
			$year = $FORM{'EndDateC'}-1900;
		}
		else { $year = (localtime($time))[5]; }
		$year+=1900;
		$PrintForm .= "<FONT FACE=\"Courier\"><INPUT TYPE=TEXT NAME=\"EndDateA\" SIZE=2";
		if ($mday) { $PrintForm .= " VALUE=$mday"; }
		$PrintForm .= "> ";
		$PrintForm .= "<SELECT NAME=\"EndDateB\">";
		foreach $key (0..11) {
			$PrintForm .= "<OPTION VALUE=\"$key\"";
			if ($key == $mon) { $PrintForm .= " SELECTED"; }
			$PrintForm .= ">$month[$key]";
		}
		$PrintForm .= "</SELECT> ";
		$PrintForm .= "<INPUT TYPE=TEXT NAME=\"EndDateC\" SIZE=4 VALUE=$year></FONT>\n";
	}
	$PrintForm .= "<P><INPUT TYPE=SUBMIT VALUE=\"Search\">";
	$PrintForm .= "</CENTER></FORM>\n<SMALL>\n";
	if ($FormExplanation) { $PrintForm .= "<P ALIGN=CENTER>$FormExplanation\n"; }
	$PrintForm .= "<P ALIGN=CENTER>";
	$PrintForm .= "Maintained with <STRONG>";
	$PrintForm .= "<A HREF=\"http://awsd.com/scripts/websearch/\">";
	$PrintForm .= "WebSearch $version</A></STRONG>.\n</SMALL>\n";
	$PrintForm .= "</TD></TR></TABLE></CENTER>";
	if ($ListOnly) {
		$PrintForm =~ s/New Search/Site Search/g;
		print "$PrintForm\n";
		$PrintForm =~ s/&/&amp;/g;
		$PrintForm =~ s/</&lt;/g;
		$PrintForm =~ s/>/&gt;/g;
		$PrintForm =~ s/"/&quot;/g;
#		$PrintForm =~ s/\n/\n<BR>/g;
		print "<P><CENTER><TABLE><TR><TD>";
		print "<STRONG>Copy the following HTML code onto any pages ";
		print "on which you want a search form like the above:</STRONG>";
		print "</TD></TR><TR><FORM><TD ALIGN=CENTER NOWRAP><FONT FACE=\"Courier\">";
		print "<TEXTAREA COLS=70 ROWS=10 WRAP=VIRTUAL>$PrintForm</TEXTAREA>";
		print "</FONT></TD></FORM></TR></TABLE></CENTER>\n";
	}
	elsif ($PrintNewForm) {
		print "$PrintForm\n";
	}
}

sub NavBar {
	$NavBar = "<P><CENTER><TABLE><TR><TD><STRONG>Matches:</STRONG></TD>";
	$prevstart = ($FORM{'first'}-$FORM{'hits'});
	$prevend = ($FORM{'last'}-$FORM{'hits'});
	if ($prevstart > 1) {
		$NavBar .= "<FORM METHOD=POST ACTION=\"$cgiurl\"><TD>";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"terms\" VALUE=\"";
		foreach $term (@terms) { $NavBar .= "$term "; }
		$NavBar .= "\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"boolean\" ";
		$NavBar .= "VALUE=\"$FORM{'boolean'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"case\" ";
		$NavBar .= "VALUE=\"$FORM{'case'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"hits\" ";
		$NavBar .= "VALUE=\"$FORM{'hits'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"first\" ";
		$NavBar .= "VALUE=\"1\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"last\" ";
		$NavBar .= "VALUE=\"$FORM{'hits'}\">";
		if ($FORM{'DateRange'} eq "Range") {
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"DateRange\" ";
			$NavBar .= "VALUE=\"$FORM{'DateRange'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateC'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateC'}\">";
		}
		$NavBar .= "<INPUT TYPE=SUBMIT ";
		$NavBar .= "VALUE=\"1 - $FORM{'hits'}\">";
		$NavBar .= "</TD></FORM>";
	}
	if ($FORM{'first'} > 1) {
		$NavBar .= "<FORM METHOD=POST ACTION=\"$cgiurl\"><TD>";
		if (($prevstart-$FORM{'hits'})>1) { $NavBar .= "<STRONG>...</STRONG></TD><TD>"; }
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"terms\" VALUE=\"";
		foreach $term (@terms) { $NavBar .= "$term "; }
		$NavBar .= "\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"boolean\" ";
		$NavBar .= "VALUE=\"$FORM{'boolean'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"case\" ";
		$NavBar .= "VALUE=\"$FORM{'case'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"hits\" ";
		$NavBar .= "VALUE=\"$FORM{'hits'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"first\" ";
		$NavBar .= "VALUE=\"$prevstart\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"last\" ";
		$NavBar .= "VALUE=\"$prevend\">";
		if ($FORM{'DateRange'} eq "Range") {
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"DateRange\" ";
			$NavBar .= "VALUE=\"$FORM{'DateRange'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateC'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateC'}\">";
		}
		$NavBar .= "<INPUT TYPE=SUBMIT ";
		$NavBar .= "VALUE=\"$prevstart - $prevend\">";
		$NavBar .= "</TD></FORM>";
	}
	$thisend = $FORM{'last'};
	if ($thisend > $matchcount) { $thisend = $matchcount; }
	$NavBar .= "<TD><STRONG>$FORM{'first'} - $thisend</STRONG></TD>";
	$nextstart = ($FORM{'first'}+$FORM{'hits'});
	$nextend = ($FORM{'last'}+$FORM{'hits'});
	if ($FORM{'last'} < $matchcount) {
		$NavBar .= "<FORM METHOD=POST ACTION=\"$cgiurl\"><TD>";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"terms\" VALUE=\"";
		foreach $term (@terms) { $NavBar .= "$term "; }
		$NavBar .= "\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"boolean\" ";
		$NavBar .= "VALUE=\"$FORM{'boolean'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"case\" ";
		$NavBar .= "VALUE=\"$FORM{'case'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"hits\" ";
		$NavBar .= "VALUE=\"$FORM{'hits'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"first\" ";
		$NavBar .= "VALUE=\"$nextstart\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"last\" ";
		$NavBar .= "VALUE=\"$nextend\">";
		if ($FORM{'DateRange'} eq "Range") {
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"DateRange\" ";
			$NavBar .= "VALUE=\"$FORM{'DateRange'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateC'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateC'}\">";
		}
		$NavBar .= "<INPUT TYPE=SUBMIT VALUE=\"";
		if ($nextend > $matchcount) { $nextend = $matchcount; }
		$nextset = $nextend - $nextstart + 1;
		$NavBar .= "$nextstart";
		unless ($nextset == 1) { $NavBar .= " - $nextend"; }
		$NavBar .= "\"></TD></FORM>";
	}
	if ($nextend < $matchcount) {
		$finalend = (int($matchcount/$FORM{'hits'})+1)*$FORM{'hits'};
		$finalstart = $finalend-$FORM{'hits'}+1;
		$NavBar .= "<FORM METHOD=POST ACTION=\"$cgiurl\"><TD>";
		if (($finalstart-$nextend)>1) { $NavBar .= "<STRONG>...</STRONG></TD><TD>"; }
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"terms\" VALUE=\"";
		foreach $term (@terms) { $NavBar .= "$term "; }
		$NavBar .= "\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"boolean\" ";
		$NavBar .= "VALUE=\"$FORM{'boolean'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"case\" ";
		$NavBar .= "VALUE=\"$FORM{'case'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"hits\" ";
		$NavBar .= "VALUE=\"$FORM{'hits'}\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"first\" ";
		$NavBar .= "VALUE=\"$finalstart\">";
		$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"last\" ";
		$NavBar .= "VALUE=\"$finalend\">";
		if ($FORM{'DateRange'} eq "Range") {
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"DateRange\" ";
			$NavBar .= "VALUE=\"$FORM{'DateRange'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"StartDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'StartDateC'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateA\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateA'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateB\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateB'}\">";
			$NavBar .= "<INPUT TYPE=HIDDEN NAME=\"EndDateC\" ";
			$NavBar .= "VALUE=\"$FORM{'EndDateC'}\">";
		}
		$NavBar .= "<INPUT TYPE=SUBMIT VALUE=\"";
		if ($finalend > $matchcount) { $finalend = $matchcount; }
		$finalset = $finalend - $finalstart + 1;
		$NavBar .= "$finalstart";
		unless ($finalset == 1) { $NavBar .= " - $finalend"; }
		$NavBar .= "\"></TD></FORM>";
	}
	$NavBar .= "</TR></TABLE></CENTER>\n";
}

sub rangedate {
	($perp_mon,$perp_day,$perp_year) = @_;
	%day_counts =
	  (1,0,2,31,3,59,4,90,5,120,6,151,7,181,
	  8,212,9,243,10,273,11,304,12,334);
	$perp_days = (($perp_year-69)*365)+(int(($perp_year-69)/4));
	$perp_days += $day_counts{$perp_mon};
	if ((int(($perp_year-68)/4) eq (($perp_year-68)/4))
	  && ($perp_mon>2)) {
		$perp_days++;
	}
	$perp_days += $perp_day;
	$perp_days -= 366;
	$perp_secs = ($perp_days*86400)+18000;
	$hour = (localtime($perp_secs))[2];
	if ($hour>0) { $perp_secs-=3600; }
	$perp_secs -= ($HourOffset*3600);
	return $perp_secs;
}

sub FindSpecifics {
	$ADVNoPrint = 1;
	$DOMAIN = $ENV{'HTTP_HOST'};
	$ROOT_URL = "http://$DOMAIN";
	if ($ENV{'REQUEST_URI'} =~ /\.pl(\/.*)$/) { $PSEUDO_QS = $1; }
	elsif ($ENV{'REQUEST_URI'} =~ /\.cgi(\/.*)$/) { $PSEUDO_QS = $1; }
	if ($ENV{'SCRIPT_NAME'} && $ENV{'PATH_INFO'}) {
		unless ($PSEUDO_QS) { $PSEUDO_QS = $ENV{'PATH_INFO'}; }
		$URI_PATH = $ENV{'SCRIPT_NAME'};
	}
	elsif ($ENV{'PATH_INFO'}) { $URI_PATH = $ENV{'PATH_INFO'}; }
	elsif ($ENV{'SCRIPT_NAME'}) { $URI_PATH = $ENV{'SCRIPT_NAME'}; }
	$URI_DIR = $URI_PATH;
	$URI_DIR =~ s/^(.*?)\/[^\/\\]*\.[^\.\/]+$/$1/;
	unless($URI_DIR){ $URI_DIR = "/"; }
	if ($ENV{'DOCUMENT_ROOT'}) { $DOC_ROOT = $ENV{'DOCUMENT_ROOT'}; }
	elsif ($ENV{'PWD'}) { $DOC_ROOT = $ENV{'PWD'}; }
	else { $DOC_ROOT = $ENV{'PATH_TRANSLATED'}; }
	$DOC_ROOT =~ tr/\\/\//;
	$DOC_ROOT =~ s/^(.+?)$URI_PATH$/$1/;
	$DOC_ROOT =~ s/^(.+?)$URI_DIR(\/)*$/$1/;
	$DOC_ROOT =~ s/^(.+?)\/$/$1/;
	$THIS_DIR = $URI_DIR;
	$THIS_DIR =~ s/^$ROOT_URL//i;
	$THIS_DIR = "$DOC_ROOT/$THIS_DIR";
	$THIS_DIR =~ s/\/\//\//g;
	$THIS_DIR =~ s/\/$//;
	return ($DOC_ROOT,$THIS_DIR,$PSEUDO_QS);
}

sub SSI_Functions {
	my $PASSED = @_[0];
	$PASSED =~ s/<!--/\n<!--/g;
	$PASSED =~ s/-->/-->\n/g;
	my @PASSED = split(/\n/,$PASSED);
	my (@included,$included_line,$SSIfilename,$SSIfileroot);
	foreach $PASSED (@PASSED) {
		if ($PASSED =~ s/<!--\s*#\s*echo \s*var\s*=\s*("|')(.+?)("|')\s*-->//i) {
			$VariableCalled = $2;
			if ($VariableCalled =~ "DATE_") {
				$SSItime = time;
				if ($VariableCalled eq "DATE_GMT") {
					($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
					  gmtime($SSItime);
					$SSItimezone = "GMT";
				}
				else {
					($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
					  localtime($SSItime);
				}
				@SSIdays = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
				@SSImonths = ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
				$wday = $SSIdays[$wday];
				$mon = $SSImonths[$mon];
				if ($hour < 10) { $hour = "0".$hour; }
				if ($min < 10) { $min = "0".$min; }
				if ($sec < 10) { $sec = "0".$sec; }
				$year += 1900;
				$PASSED = "$wday, $mday-$mon-$year $hour:$min:$sec $SSItimezone";
			}
			else { $PASSED = "$ENV{$VariableCalled}"; }
			if ($PASSED eq "") { $PASSED = "SSI Tag (ECHO=\"$VariableCalled\") Not Supported"; }
		}
		elsif (!($AdminRun) && ($PASSED =~ /<!--InsertAdvert\s*(.*)-->/i)) {
			&insertadvert($1);
			$PASSED = "";
		}
		elsif ($PASSED =~ /<!--\s*#\s*include/) {
			if ($PASSED =~ s/<!--\s*#\s*include \s*virtual\s*=\s*("|')(.+?)("|')\s*-->//i) {
				$SSIfileroot = "$SSIvirtual";
				$SSIfilename = $2;
			}
			elsif ($PASSED =~ s/<!--\s*#\s*include \s*file\s*=\s*("|')(.+?)("|')\s*-->//i) {
				$SSIfileroot = "$SSIfile/";
				$SSIfilename = $2;
			}
			if ($SSIfilename =~ /(.pl|.cgi)/) {
				use LWP::Simple;
				getprint ("http://$ENV{'HTTP_HOST'}$SSIfilename");
				$PASSED = "";
			}
			elsif ($SSIfilename) {
				$SSIfilename = $SSIfileroot.$SSIfilename;
				open (INCLUDED,"$SSIfilename");
				@included=<INCLUDED>;
				close (INCLUDED);
				foreach $included_line (@included) {
					&SSI_Functions($included_line);
				}
				$PASSED = "";
			}
			else {
				$PASSED = "SSI Tag (INCLUDE) Not Supported";
			}
		}
		elsif ($PASSED =~ /<!--\s*#\s*exec/) {
			if ($PASSED =~ /<!--\s*#\s*exec \s*cmd/) {
				$PASSED = "SSI Tag (EXEC CMD) Not Supported";
			}
			elsif ($PASSED =~ s/<!--\s*#\s*exec \s*cgi\s*=\s*("|')(.+?)("|')\s*-->//i) {
				$SSIscript = $2;
				use LWP::Simple;
				getprint ("http://$ENV{'HTTP_HOST'}$SSIscript");
				$PASSED = "";
			}
			else {
				$PASSED = "SSI Tag (EXEC) Not Supported";
			}
		}
		elsif ($PASSED =~ /printenv/) {
			$PASSED = "";
			foreach $key (keys %ENV) {
				$PASSED .= "$key=$ENV{$key}\n";
			}
		}
		elsif ($PASSED =~ /<!--/) { $PASSED = "SSI Tag Not Supported"; }
		if ($PASSED) { print "$PASSED\n"; }
		$PASSED = "";
	}
}

sub Header {
	($title) = @_;
	print "<HTML><HEAD><TITLE>$title</TITLE>\n";
	if ($meta_file) {
		open (HEADLN,"$meta_file");
		@headln = <HEADLN>;
		close (HEADLN);
		foreach $line (@headln) { &SSI_Functions($line); }
	}
	print "</HEAD>\n";
	print "<BODY $bodyspec>\n";
	if ($header_file) {
		open (HEADER,"$header_file");
		@header = <HEADER>;
		close (HEADER);
		foreach $line (@header) { &SSI_Functions($line); }
	}
}

sub Footer {
	if ($footer_file) {
		open (FOOTER,"$footer_file");
		@footer = <FOOTER>;
		close (FOOTER);
		foreach $line (@footer) { &SSI_Functions($line); }
	}
	print "</BODY></HTML>\n";
}

sub Error_SearchIndex {
	&Header("Error");
	print "<P>The script was unable to create the search index file. ";
	print "This is most likely either because the file's location has been ";
	print "incorrectly defined, or because the script doesn't have permission ";
	print "to write files to the designated directory.\n";
	&Footer;
	exit;
}
