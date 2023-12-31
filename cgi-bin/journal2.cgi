#!/usr/bin/perl

# look for write_index in this file.  It's the only modification-set in here.

use CGI;
$query = new CGI;

$BASE_DIR='/home/barefoot_rob/temp.robnugen.com/journal';

$write_index=0;   # the tentative beginning of showing only the file contents

%monthNames =              # this is how directory name '03' is translated to 'mar'
    ( '01' => 'january',
      '02' => 'february',
      '03' => 'march',
      '04' => 'april',
      '05' => 'may',
      '06' => 'june',
      '07' => 'july',
      '08' => 'august',
      '09' => 'september',
      '10' => 'october',
      '11' => 'november',
      '12' => 'december'   );

#$debug = $query->param('debug');

if($dir = $query->param('dir'))
{
    $dir =~ s!^[\./~]*!!;   # chop off any number of . / or ~ chars at start of $dir
    $dir =~ s!/\.\.!!g;     # chop out any number of /.. within $dir
    $dir =~ s!/$!!;         # chop off very end / if it exists
    ($dir == "latest") && ($dir = &getLatestDir);

} else {
    $dir = "";
}

chdir("../journal/$dir") || die "cannot get to $dir";

$backdir = $dir;
$backdir =~ s!\w*$!!;  # remove last word of $dir.  if $dir = /1999/01  then $backdir = /1999/

# now we have changed to the directory requested.   Get a list of all files in this directory

#======
#  Check to see what file was selected.  Then when we scan through looking for index.html, 
#  we can also determine what files are prev and next to selected file.
#======

if ($fileParam = $query->param('file'))   # true if file parameter is in URL
{
    $req_file = "$BASE_DIR/$dir/$fileParam";
}
else
{
    $req_file = 0;
}

# these next lines will show all files (including those that don't
# start with digits if a parameter called all exists

if($query->param('all')) {
    @files_in_dir = <*>;
}
else {
    @files_in_dir = <[0-9]*>;
}

print "Content-type: text/html\n\n";

foreach $file (sort @files_in_dir)   # look for index.html.  If it exists, refresh to that document.
{
    if($found_prev eq 1)
    {
	$found_prev = 2;
	$next_file=$file;
    }
	
    if($file eq $fileParam)
    {
	$prev_file=$file_n_minus_one;
	$found_prev=1;
    }
    if($file =~ /index.html/)
    {
	&abortMission;#  index.html exists, so use it and not this script
	exit;
    }

    # if no file was requested, then nothing could have matched above, 
    # therefore no prev_file has been set
    unless($req_file)
    {
	# make sure it's a file with -f
	if (-f $file_n_minus_one) {
	    $prev_file=$file_n_minus_one;
	}
    }


    $file_n_minus_one=$file;   # seed the prev_file thing
}


&printHead;


print "<body>";
if($write_index) {
    print "<table border='0' width='100%'>";
    print"<tr><td width='20%' valign='top'>";

# the next two arguments will be used if a file is not selected on URL
#
#  if a file with 'description' in its name exists, it will be used.
#  otherwise, the last file (alphabetically) in the directory will be used, if one exists
#
$description_exists = 0; 
$last_file = 0;

print <<TopOfColumn;

<p><a href="/"
onMouseOver="imageOn('home'); return true;"
onMouseOut="imageOff('home'); return true;"><img
src="/images/front/home_off.gif" width=100 height=35 border=0
name=home></a>

<br>a 2 digit prefix
<br>indicates date
TopOfColumn

foreach $file (@files_in_dir)   # for each file that matches file specification *  (all of them!)
{   

    unless($file =~ /images$/)
    {
	if($file =~ /description/) 
	{
	    $description_exists = $file;    # a description exists.  remember the filename and use it if no file was chosen
	}
	else {
	    $fullname = "$BASE_DIR/$dir/$file";
	    if (-d $fullname)    # the file is a directory
	    { 
		# in the next line "$monthNames{$dir}" means using $dir as key in $monthNames, print the value.  
		# (if $dir == '01' then print 'jan')
		if(($file =~ /^\d\d$/) && (1 <= $file) && ($file <= 12)) #    if it's exactly two digits and between 1 and 12
		{
		    print "<br><a href='../cgi-bin/journal.cgi?dir=$dir/$file'>$monthNames{$file}</a>\n";
		}
		else 
		{
		    print "<br><a href='../cgi-bin/journal.cgi?dir=$dir/$file'>$file</a>\n";
		}
	    }

	    if (-f $fullname) # the file is a file
	    { 
		print "<br><a href='../cgi-bin/journal.cgi?dir=$dir&file=$file'>$file</a>\n";
		$last_file = $file;      # remember what is the last file in the list
	    }
	    # sendmail to me because we found a file type that we couldn't handle.
	}  # end else ( the file is not "description" )
    }

}

print "<p><a href='../cgi-bin/journal.cgi?dir=$backdir'>$backdir index</a>";
print "<br><a href='../cgi-bin/journal.cgi'>journal index</a>";

print <<Stuff;
</td>
<td valign="top">
Stuff

}    # here ends the enormous if ($write_index)

&drawPrevNextFile;

unless ($req_file) {
    if ($last_file)
    {
	$req_file = 1;
	$file = $last_file;
    }
    if ($description_exists)
    {
	$req_file = 1;
	$file = $description_exists;
    }
}
else {
        $file=$fileParam;
    }
if ($req_file) {

    $file =~ s/^\W*//;  # chop off everything that is not a word from the beginning
# if $' matches, SENDMAIL to me what was chopped off

    if ($file =~ /html?$|txt$/)   # filename ends with htm, html, or txt
    {
	unless ($file =~ /html?$/) {    print "<pre>";  }   # matches htm(l) at the end of the word

	open (IN, "$file") or die "Can't open $file for reading: $!";
	flock(IN, 1)            or die "Can't get LOCK_SH on $file: $!";
	while (<IN>) {
	    print;
	}
	close IN                or die "Can't close $file: $!";

	unless ($file =~ /html?$/) {    print "</pre>";  }   # matches htm(l) at the end of the word
    }
    elsif ($file =~ /jpe?g$|gif$/)  # filename ends with jpg, jpeg, or gif
    {
	$fullname = "../journal/$dir/$file";
	print "<img src='$fullname'>";
	print "<br>$file";
    }
    else
    {
	print "<p>Unknown file extension on $file</p>";
	# SENDMAIL to me
    }
} else {

    print <<nothin;
<h1>Rob's Life</h1>

<p>Select an item from the index to the left.</p>
nothin

}

&drawPrevNextFile;


if($write_index) {
   print "</td></tr></table>";
}
print "</body>";

sub drawPrevNextMonth
{
    if ($prev_month || $next_month) 
    {
	print "<p class=small>";
	if ($prev_month) {
	    print "<a href='../cgi-bin/journal.cgi?dir=$dir&month=$prev_month'>prev</a> ";
	}
	
	if ($prev_month and $next_month) {
	    print " : ";
	}
	
	if ($next_month) {
	    print "<a href='../cgi-bin/journal.cgi?dir=$dir&month=$next_month'>next</a>";
	}
	print "</p>";
    }
}

sub drawPrevNextFile
{
    if ($prev_file || $next_file) 
    {
	print "<p class=small>";
	if ($prev_file) {
	    print "<a href='../cgi-bin/journal.cgi?dir=$dir&file=$prev_file'>prev</a> ";
	}
	
	if ($prev_file and $next_file) {
	    print " : ";
	}
	
	if ($next_file) {
	    print "<a href='../cgi-bin/journal.cgi?dir=$dir&file=$next_file'>next</a>";
	}
	print "</p>";
    }
}

############################
#
#  getLatestDir
#
#  This subroutine is designed to find the latest year and latest month in that year in my journal directory
#
#  It assumes a few things:   
#  1) The script is being run from /home/barefoot_rob/temp.robnugen.com/cgi-bin
#  2) ../journal is my journal directory
#
###############################################3333
sub getLatestDir
{
    chdir("../journal");                                          # go to journal dir
    @list = <*>;                                                  # get list of files in dir
    foreach $entry(sort @list)                                    # look through each
    {
	(-d $entry) && (0 != $entry) && ($last = $entry);         # if it's a dir and numeric then we want it
    }
    chdir($last);                                                 # go to directory we just found

    @list = <*>;                                                  # get list of files in dir
    foreach $entry(sort @list)                                    # look through each
    {
	(-d $entry) && (0 != $entry) && ($lastM = $entry);         # if it's a dir and numeric then we want it
    }

    chdir("/home/barefoot_rob/temp.robnugen.com/cgi-bin");                     # go back to start so script can work normally
    $last .= "/$lastM";                                           # return $last concatenated with "/" and $lastM
}

sub abortMission
{
    print <<AbortMission;
<html>
<head>
<title>index.html exists!</title>
<script language="JavaScript">

function refresh()
{
  document.location = "http://www.robnugen.com/journal/$dir";
}

</script>
</head>
<body onload="refresh()">

Click <a href="http://www.robnugen.com/journal/$dir">here</a>

<p><a href="/">home</a>

</body>
</html>
AbortMission
}

sub printScript
{
    print <<printScript;
<script language="JavaScript">

<!-- hide from non-JavaScript Browsers

homeOn = new Image()
homeOn.src = "/images/front/home_on.gif"
homeOff = new Image()
homeOff.src = "/images/front/home_off.gif"

function imageOff(name)
{
   imageName = eval(name + "Off.src");
   document[name].src = imageName;
   return true;
}

function imageOn(name)
{
   imageName = eval(name + "On.src");
   document[name].src = imageName;
   return true;
}

// - stop hiding -->

</script> 
printScript
}  #end printScript



sub printStyle
{
    print <<printStyle;
<style>
<!--
    body        { color : black; font-family : Arial,sans-serif; 
		  margin-top : 5%; 
		  font-weight : 12pt; background : white}
    h1          { font-size : 24pt; color : red; font-family : Arial;
		  text-align : center }
    h1.black    { font-size : 24pt; color : black; font-family : Arial;
		  text-align : center }
    pre         { color : blue; bgcolor : yellow }
  p             { color : black; font-family : Arial,sans-serif; 
		  font-size : 12pt}
  p.small       { color : black; font-family : Arial,sans-serif; 
		  font-size : 8pt}
  p.description { color : green; font-family : Arial,sans-serif; 
		  font-size : 24pt }
  p.dream       { color : green; font-family : Arial,sans-serif; 
		  font-size : 12pt; font-style : italic}
  p.lucid       { color : green; font-family : Arial,sans-serif; 
		  font-size : 12pt;}
  p.grafitti    { color : red; font-family : Arial,sans-serif; 
		  font-size : 12pt; font-style : italic}
  p.message     { color : blue; font-family : Arial,sans-serif; 
		  font-size : 12pt}
  p.date        { color : blue; font-family : Arial,sans-serif; 
		  font-size : 16pt }
  p.note        { color : blue; font-size : 10pt } 
  p.anger       { color : red; font-size : 24pt; font-style : italic } 

-->
</style>

printStyle
}

sub printHead
{
    print '<html>';
    print '<head>';
    &printScript;
    &printStyle;
    print "<title>Rob's Life</title>\n";
    print "<link rel='next' href='../cgi-bin/journal.cgi?dir=$dir&file=$next_file'>\n";
    print "<link rel='prev' href='../cgi-bin/journal.cgi?dir=$dir&file=$prev_file'>\n";
    print "</head>\n";
}
