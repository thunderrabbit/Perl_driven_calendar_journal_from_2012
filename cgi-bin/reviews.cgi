#!/usr/bin/perl

use CGI;
$query = new CGI;

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

if($dir = $query->param('dir'))
{
    $dir =~ s!^[\./~]*!!;   # chop off any number of . / or ~ chars at start of $dir
    $dir =~ s!/\.\.!!g;     # chop out any number of /.. within $dir
    $dir =~ s!/$!!;         # chop off very end / if it exists

} else {
    $dir = "";
}

chdir("../ktru/reviews/$dir") || die "cannot get to $dir";

$backdir = $dir;
$backdir =~ s!\w*$!!;  # remove last word of $dir.  if $dir = /1999/01  then $backdir = /1999/

# now we have changed to the directory requested.   Get a list of all files in this directory

@files_in_dir = <*>;

print "Content-type: text/html\n\n";

foreach $file (@files_in_dir)   # look for index.html.  If it exists, refresh to that document.
{
    if($file =~ /index.html/)
    {
	print <<AbortMission;
<html>
<head>
<title>index.html exists!</title>
</head>
<body>

<p>Yay!  <a href="../ktru/reviews/$dir/index.html">index.html</a> exists in this
directory.  To view the contents of the directory, please <a
href="../ktru/reviews/$dir/index.html">click here</a>.

<p>Or go <a href="../cgi-bin/reviews.cgi?dir=$backdir">back to $backdir index</a>

</body>
</html>
AbortMission
    exit;
    }
}

print <<EndOfHead;

<html>
<head>
<title>$newdir</title>
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

<style>
<!--
    body        { color : black; font-family : Arial,sans-serif; 
		  margin-top : 5%; Arial; 
		  font-weight : 12pt; bgcolor : white}
    h1          { font-size : 24pt; color : red; font-family : Arial;
		  text-align : center }
    pre         { color : blue; bgcolor : yellow }
  p             { color : black: font-family : Arial,sans-serif; 
		  font-size : 12pt}
  p.description { color : green; font-family : Arial,sans-serif; 
		  font-size : 24pt }
  p.date        { color : blue; font-family : Arial,sans-serif; 
		  font-size : 16pt }
  p.note        { color : blue; font-size : 10pt } 

-->
</style>
</head>
EndOfHead

print <<BeginTableContents;
<body>

<table border="0" width="100%">
<tr><td width="25%" valign="top">

BeginTableContents


if ($file = $query->param('file'))   # true if file parameter is in URL
{
    $req_file = "/home/barefoot_rob/temp.robnugen.com/ktru/reviews/$dir/$file";
}
else
{
    $req_file = 0;
}

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

<br>2 digit prefix
<br>indicates review #
TopOfColumn


foreach $file (@files_in_dir)   # for each file that matches file specification *  (all of them!)
{   

    unless($file =~ /.pl$/)
    {
	if($file =~ /description/) 
	{
	    $description_exists = $file;    # a description exists.  remember the filename and use it if no file was chosen
	}
	else {
	    $fullname = "/home/barefoot_rob/temp.robnugen.com/ktru/reviews/$dir/$file";
	    if (-d $fullname)    # the file is a directory
	    { 
		# in the next line "$monthNames{$dir}" means using $dir as key in $monthNames, print the value.  
		# (if $dir == '01' then print 'jan')
		if(($file =~ /^\d\d$/) && (1 <= $file) && ($file <= 12)) #    if it's exactly two digits and between 1 and 12
		{
		    print "<br><a href='../cgi-bin/reviews.cgi?dir=$dir/$file'>$monthNames{$file}</a>\n";
		}
		else 
		{
		    print "<br><a href='../cgi-bin/reviews.cgi?dir=$dir/$file'>$file</a>\n";
		}
	    }

	    if (-f $fullname) # the file is a file
	    { 
		print "<br><a href='../cgi-bin/reviews.cgi?dir=$dir&file=$file'>$file</a>\n";
		$last_file = $file;      # remember what is the last file in the list
	    }
	    # sendmail to me because we found a file type that we couldn't handle.
	}  # end else ( the file is not "description" )
    }

}

print "<p><a href='../cgi-bin/reviews.cgi?dir=$backdir'>$backdir index</a>";
print "<br><a href='../cgi-bin/reviews.cgi'>review index</a>";

print <<Stuff;
</td>
<td valign="top">
Stuff

unless ($req_file) 
{
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
	$fullname = "../ktru/reviews/$dir/$file";
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

print <<EndHTML;

</td></tr></table>
</body>

EndHTML

