#!/usr/bin/perl

use CGI;
$query = new CGI;

$THIS_FILE = "/cgi-bin/images.cgi";
$WEB_BASE_DIR = "/images";
$BASE_DIR = "/home/barefoot_rob/temp.robnugen.com$WEB_BASE_DIR";

$BIG = 1;
$THUMB = 2;
$BOTH = $BIG + $THUMB;

$TABLE_BORDER=0;

&getParams;

&printContentType;

&setupDirs;

### go to main image directory
chdir($fulldir) || die "cannot get to $fulldir";
@pics_in_dir = <*>;
    
$thumbs = 0;  # assume thumbs directory does not exist
###  put all files into an associative array.  thumbs should not be in here.
foreach $file (@pics_in_dir)
{
    if(-d $file) {
	if($file eq "thumbs") {
	    $thumbs = 1; 
	}
	else {
	    push(@dirs_in_dir,"$dir/$file");  # add dir name to dir array
	}
	
    }
    if(-f $file) {
	if($file =~ /(.jpg|.jpeg|.gif)$/i)  {
	    $imageExists{$file} += $BIG;
	    
	}
    }
}


### now go to thumb directory
if($thumbs)
{
    chdir($thumbdir) || die "cannot get to $thumbdir";
    @pics_in_thumbdir = <*.jpg *.jpeg *.gif *.JPG>;

    ### go through files in thumb directory.  If appropriate, put them in array
    foreach $file (@pics_in_thumbdir) {
	# if file is in images array already, then it exists in both dirs
	$imageExists{$file} += $THUMB; 

    }
}

&printHead;

print "<body><table border=$TABLE_BORDER width='100%'>";

if($dir_info=&getContents("$fulldir/description.txt")) {
    print "<tr><td colspan=2 align=center>$dir_info";
}

print "<tr><td align=left>";

print <<TopOfColumn;

<p><a href="/"
onMouseOver="imageOn('home'); return true;"
onMouseOut="imageOff('home'); return true;"><img
src="/images/front/home_off.gif" width=100 height=35 border=0
name=home></a>
TopOfColumn

&printDirs;

foreach $key (sort keys %imageExists)
{
    print "\n<br>";
    if(($imageExists{$key} == $BIG) || ($imageExists{$key} == $BOTH)) {
	print "<a href='$THIS_FILE?dir=$dir&file=$key'>";
    }

    if(($imageExists{$key} == $THUMB) || ($imageExists{$key} == $BOTH)) {
	print "<img src='$webthumb/$key'>";
    }

    if($thumb_info=&getContents("$thumbdir/$key.txt")) {
	print "<br>$thumb_info";
    }
    else {
	print "<br>$key";
    }

    if(($imageExists{$key} == $BIG) || ($imageExists{$key} == $BOTH)) {
	print "</a>";
    }
}

###	       ###  if we are looking at big pics
###	       unless ($picInfo{$file} = &getContents("$dir/$file.txt")) {
###		   $picInfo{$file} = $file;
###	       }

if ($file_param) {
    print "\n\n<td align=center valign=top><img src='$webdir/$file_param'>";

    if($pic_info=&getContents("$fulldir/$file_param.txt")) {
	print "\n<br>$pic_info";
    }
}

print "</table></body></html>";


sub getParams
{
    if($dir = $query->param('dir'))
    {
    	$dir =~ s!^[\./~]*!!;   # chop off any number of . / or ~ chars at start of $dir
    	$dir =~ s!/\.\.!!g;     # chop out any number of /.. within $dir
    	$dir =~ s!/$!!;         # chop off very end / if it exists
    } 
    else 
    {
    	$dir = "";
    }
    
    $debug_dirs = $query->param('debug_dirs');

    $file_param = $query->param('file');

}   # end sub getParams

sub printContentType {    print"Content-type: text/html\n\n"; }

sub printHead
{
   print "<html>";
   print "<head>";
   &printStyle;
   &printScript;
   print "</head>";
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
    print << "EOS"
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
EOS
}

####
#
#  getContents receives 1 filename as parameter
#  if the file exists, it returns its contents in one variable
#  if the file does not exist, "" is returned.
#
sub getContents
{
    local $text = '';
    local($file) = @_;

    if(-f $file) {          # the file exists
	open(INFO,$file);
	while(<INFO>)	{
	    $text .= $_;    # concatenate the contents
	}
	$text;              # this will be returned
    }
    else {
	"";                 # file does not exist; return "";
    }

}   # end getContents


sub setupDirs
{
    # if $dir has a value, add it to $BASE_DIR and call it $fulldir
    if($dir)
    {    
    	$fulldir = "$BASE_DIR/$dir"; 
    	$webdir = "$WEB_BASE_DIR/$dir";
    }
    else 
    {
    	$fulldir = $BASE_DIR;
    	$webdir = $WEB_BASE_DIR;
    }   
    $backdir = $dir;
    $backdir =~ s!\w*$!!;  # if $dir = /1999/01  then $backdir = /1999/
    $thumbdir = "$fulldir/thumbs";
    $webthumb = "$webdir/thumbs";

    if ($debug_dirs)
    {
	&printHead;
    	print"<body>";
	print "<br>this = >$THIS_FILE<";
    	print "<br>base = >$BASE_DIR<";
    	print "<br>dir = >$dir<";
    	print "<br>backdir = >$backdir<";
    	print "<br>thumbdir = >$thumbdir<";
    	print "<br>fulldir = >$fulldir<";
    	print "<br>webbase = >$WEB_BASE_DIR<";
    	print "<br>webdir = >$webdir<";
    	print "<br>webthumb = >$webthumb<";
    }
}

#######################################
#
#  printDirs prints links to all the dirs in @dirs_in_dir plus the parent directory
#
sub printDirs
{
    print "\n\n<p><a href='$THIS_FILE?dir=$backdir'>parent dir</a>\n<br>";
    foreach $subdir (sort @dirs_in_dir) {
	print "<br><a href='$THIS_FILE?dir=$subdir'>";
	if ($dir_info=&getContents("$BASE_DIR/$subdir.txt")) {
	    print "$dir_info</a>\n"; 
	}
	else {
	    $subdir =~ s!.*/(\w*)$!$1!;
	    print "$subdir</a>\n";
	}
    }
}












