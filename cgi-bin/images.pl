#!/usr/bin/perl -wT

# Below usage came from here:  http://www.unix.org.ua/orelly/linux/cgi/ch05_02.htm

use strict;
use CGI;

$CGI::DISABLE_UPLOADS = 1;
$CGI::POST_MAX        = 102_400;   #  100 KB

$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};


my $query = new CGI;

use lib qw (.);  # allows these to be used with switch  -T (taint mode)

# Above usage came from here:  http://www.unix.org.ua/orelly/linux/cgi/ch05_02.htm


# ------ changed according to above#!/usr/bin/perl -w
# ------ changed according to aboverequire "allowSource.pl";
# ------ changed according to aboverequire "setCookies.pl";
# ------ changed according to above
# ------ changed according to above## daysold.pl does a decent job of handling cookies, parameters and form fields
# ------ changed according to above
# ------ changed according to aboveuse strict;
# ------ changed according to aboveuse CGI qw(:all fatalsToBrowser);
# ------ changed according to aboveuse CGI::Cookie;

# use CGI qw(:all fatalsToBrowser);
# use CGI::Cookie;

use lib qw (.);  # allows these to be used with switch  -T (taint mode)
require "allowSource.pl";
require "setCookies.pl";
require "mkdef.pl";

print $query->header, $query->start_html("title");

my ($full_dir,$path,$env_var,$user,$pass,$name,%write_cookies,%read_cookies,%query_string_hash);

my $WEB_BASE_DIR = "/images";
my $BASE_DIR = "/home/thunderrabbit/robnugen.com$WEB_BASE_DIR";

# my $query = new CGI;

&get_directory_param;  # this will die on invalid dir

my @dir_contents = qx/ls -1p $full_dir/;

# I don't care if there is an index.  We are creating a new index.   &print_refresh_iff_index(@dir_contents);

&print_directories(@dir_contents);
exit;

&print_files(@dir_contents);

sub print_refresh_iff_index {

#try: The redirect() function redirects the browser to a different URL. If you use redirection like this, you should not print out a header as well.
#try: 
#try:     print $query->redirect(-uri=>'http://somewhere.else/in/movie/land',-nph=>1);
#try:                            
#try: 
#try: The -nph parameter, if set to a true value, will issue the correct headers to work with an NPH (no-parse-header) script. This is important to use with certain servers, such as Microsoft Internet Explorer, which expect all their scripts to be NPH.

    my @dir_contents = @_;
    foreach (@dir_contents) {
	if (/^index./) {
#	    print $query->redirect(-uri=>$WEB_BASE_DIR . "/" . $_, -nph=>1);
	    print $query->p("in print_refresh_iff_index thinks it found an index:");
	    print $query->p($WEB_BASE_DIR . "/" . $_);
	}
    }
}

sub print_directories  {
    my @dir_contents = @_;
    my $url = $query->url(-absolute=>1);

    foreach (@dir_contents) {
	if (/\/$/) { # a / at the end means it is a directory
	    print $query->a({-href=>"$url?dir=$path$_"}, "$_");
	}
    }
}

sub print_files {
    my @dir_contents = @_;
    foreach (@dir_contents) {
	unless (/\/$/) { # a / at the end means it is a directory
	    print $query->pre("$_");
	}
    }
}

sub get_directory_param {
#!-  *****************************************************************************************************
#!-  *  
#!-  *  Okay, for real, yo: step back and redesign the user interface from
#!-  *  scratch.  I think it would be cool to sorta use the journal calendar
#!-  *  idea (for sequencing) and the journal topics idea (for locating /
#!-  *  slash topics...)  AND WE SHOULD ADD geotags - THE LAT. LONG. OF THE
#!-  *  PICTURES.  I'm dreaming of a map above the calendar column (with a RED
#!-  *  DOT showing where I am) that when clicked will allow pics to be
#!-  *  snagged by location in the world.  And why not journal entries??
#!-  *  
#!-  *****************************************************************************************************

    my ($dir) = &mkdef($query->param("dir"));
    warn ("1 dir should be long: $dir");

    $dir =~ s/^[\/|\.]*//g;  # wipe any / or . from front of directory path.
    warn ("2 dir without ../../:   $dir");

    if ($dir =~ m/((\w{1}[\w\-\.]*\/?)*)/m)     # repetitions of words/ words can include . - _, but not start with them.
    {
	$dir = $1;
    warn ("dir is $dir");
    }
    else
    {
	$dir = "";
    warn ("dir did not match");
    }

    $path = &mkdef($dir);
    $full_dir = $BASE_DIR . "/" . $path;
    warn ("basedir is $BASE_DIR");
    warn ("path is $path");
    warn ("try to open directory $full_dir");
    unless (-d $full_dir) {
	print $query->h3("cannot open directory $dir");
	die "cannot open directory $full_dir";
    }
}

print $query->h3("$full_dir"), "\n";

print $query->p( $query->start_form(-name=>'form1'), "\n",

#		     $query->popup_menu(-name=>'imageSelectList',
#					-values=>\@image_list,
#					-onChange=>'form1.image.click()'),
		 $query->p("dir", $query->textfield(-name=>'dir',-size=>12)), "\n",
		 $query->end_form);

foreach $env_var qw(HTTP_COOKIE) {
    print $query->br("$env_var</B> = $ENV{$env_var}"), "\n";
}


&allowSource;

print $query->end_html;

#$-#!/usr/bin/perl
#$-
#$-use CGI;
#$-$query = new CGI;
#$-
#$-$THIS_FILE = "/cgi-bin/images.pl";
#$-
#$-$BIG = 1;
#$-$THUMB = 2;
#$-$BOTH = $BIG + $THUMB;
#$-
#$-$TABLE_BORDER=0;
#$-
#$-&getParams;
#$-&printContentType;
#$-&setupDirs;
#$-
#$-### go to main image directory
#$-chdir($fulldir) || die "cannot get to $fulldir";
#$-@pics_in_dir = <*>;
#$-    
#$-$thumbs = 0;  # assume thumbs directory does not exist
#$-###  put all files into an associative array.  thumbs should not be in here.
#$-foreach $file (@pics_in_dir)
#$-{
#$-    if(-d $file) {
#$-	if($file eq "thumbs") {
#$-	    $thumbs = 1; 
#$-	}
#$-	else {
#$-	    push(@dirs_in_dir,"$dir/$file");  # add dir name to dir array
#$-	}
#$-	
#$-    }
#$-    if(-f $file) {
#$-	if($file =~ /(.jpg|.jpeg|.gif)$/i)  {
#$-	    $imageExists{$file} += $BIG;
#$-	    
#$-	}
#$-    }
#$-}
#$-
#$-
#$-### now go to thumb directory
#$-if($thumbs)
#$-{
#$-    chdir($thumbdir) || die "cannot get to $thumbdir";
#$-    @pics_in_thumbdir = <*.jpg *.jpeg *.gif *.JPG>;
#$-
#$-    ### go through files in thumb directory.  If appropriate, put them in array
#$-    foreach $file (@pics_in_thumbdir) {
#$-	# if file is in images array already, then it exists in both dirs
#$-	$imageExists{$file} += $THUMB; 
#$-
#$-    }
#$-}
#$-
#$-&printHead;
#$-
#$-print "<body><table border=$TABLE_BORDER width='100%'>";
#$-
#$-if($dir_info=&getContents("$fulldir/description.txt")) {
#$-    print "<tr><td colspan=2 align=center>$dir_info";
#$-}
#$-
#$-print "<tr><td align=left>";
#$-
#$-print <<TopOfColumn;
#$-
#$-<p><a href="/"
#$-onMouseOver="imageOn('home'); return true;"
#$-onMouseOut="imageOff('home'); return true;"><img
#$-src="/images/front/home_off.gif" width=100 height=35 border=0
#$-name=home></a>
#$-TopOfColumn
#$-
#$-&printDirs;
#$-
#$-foreach $key (sort keys %imageExists)
#$-{
#$-    print "\n<br>";
#$-    if(($imageExists{$key} == $BIG) || ($imageExists{$key} == $BOTH)) {
#$-	print "<a href='$THIS_FILE?dir=$dir&file=$key'>";
#$-    }
#$-
#$-    if(($imageExists{$key} == $THUMB) || ($imageExists{$key} == $BOTH)) {
#$-	print "<img src='$webthumb/$key'>";
#$-    }
#$-
#$-    if($thumb_info=&getContents("$thumbdir/$key.txt")) {
#$-	print "<br>$thumb_info";
#$-    }
#$-    else {
#$-	print "<br>$key";
#$-    }
#$-
#$-    if(($imageExists{$key} == $BIG) || ($imageExists{$key} == $BOTH)) {
#$-	print "</a>";
#$-    }
#$-}
#$-
#$-###	       ###  if we are looking at big pics
#$-###	       unless ($picInfo{$file} = &getContents("$dir/$file.txt")) {
#$-###		   $picInfo{$file} = $file;
#$-###	       }
#$-
#$-if ($file_param) {
#$-    print "\n\n<td align=center valign=top><img src='$webdir/$file_param'>";
#$-
#$-    if($pic_info=&getContents("$fulldir/$file_param.txt")) {
#$-	print "\n<br>$pic_info";
#$-    }
#$-}
#$-
#$-print "</table></body></html>";
#$-
#$-
#$-sub getParams
#$-{
#$-    if($dir = $query->param('dir'))
#$-    {
#$-    	$dir =~ s!^[\./~]*!!;   # chop off any number of . / or ~ chars at start of $dir
#$-    	$dir =~ s!/\.\.!!g;     # chop out any number of /.. within $dir
#$-    	$dir =~ s!/$!!;         # chop off very end / if it exists
#$-    } 
#$-    else 
#$-    {
#$-    	$dir = "";
#$-    }
#$-    
#$-    $debug_dirs = $query->param('debug_dirs');
#$-
#$-    $file_param = $query->param('file');
#$-
#$-}   # end sub getParams
#$-
#$-sub printContentType {    print"Content-type: text/html\n\n"; }
#$-
#$-sub printHead
#$-{
#$-   print "<html>";
#$-   print "<head>";
#$-   &printStyle;
#$-   &printScript;
#$-   print "</head>";
#$-}
#$-
#$-sub printScript
#$-{
#$-    print <<printScript;
#$-<script language="JavaScript">
#$-
#$-<!-- hide from non-JavaScript Browsers
#$-
#$-homeOn = new Image()
#$-homeOn.src = "/images/front/home_on.gif"
#$-homeOff = new Image()
#$-homeOff.src = "/images/front/home_off.gif"
#$-
#$-function imageOff(name)
#$-{
#$-   imageName = eval(name + "Off.src");
#$-   document[name].src = imageName;
#$-   return true;
#$-}
#$-
#$-function imageOn(name)
#$-{
#$-   imageName = eval(name + "On.src");
#$-   document[name].src = imageName;
#$-   return true;
#$-}
#$-
#$-// - stop hiding -->
#$-
#$-</script> 
#$-printScript
#$-}  #end printScript
#$-
#$-sub printStyle
#$-{
#$-    print << "EOS"
#$-<style>
#$-<!--
#$-    body        { color : black; font-family : Arial,sans-serif; 
#$-		  margin-top : 5%; Arial; 
#$-		  font-weight : 12pt; bgcolor : white}
#$-    h1          { font-size : 24pt; color : red; font-family : Arial;
#$-		  text-align : center }
#$-    pre         { color : blue; bgcolor : yellow }
#$-  p             { color : black: font-family : Arial,sans-serif; 
#$-		  font-size : 12pt}
#$-  p.description { color : green; font-family : Arial,sans-serif; 
#$-		  font-size : 24pt }
#$-  p.date        { color : blue; font-family : Arial,sans-serif; 
#$-		  font-size : 16pt }
#$-  p.note        { color : blue; font-size : 10pt } 
#$-
#$--->
#$-</style>
#$-EOS
#$-}
#$-
#$-####
#$-#
#$-#  getContents receives 1 filename as parameter
#$-#  if the file exists, it returns its contents in one variable
#$-#  if the file does not exist, "" is returned.
#$-#
#$-sub getContents
#$-{
#$-    local $text = '';
#$-    local($file) = @_;
#$-
#$-    if(-f $file) {          # the file exists
#$-	open(INFO,$file);
#$-	while(<INFO>)	{
#$-	    $text .= $_;    # concatenate the contents
#$-	}
#$-	$text;              # this will be returned
#$-    }
#$-    else {
#$-	"";                 # file does not exist; return "";
#$-    }
#$-
#$-}   # end getContents
#$-
#$-
#$-sub setupDirs
#$-{
#$-    # if $dir has a value, add it to $BASE_DIR and call it $fulldir
#$-    if($dir)
#$-    {    
#$-    	$fulldir = "$BASE_DIR/$dir"; 
#$-    	$webdir = "$WEB_BASE_DIR/$dir";
#$-    }
#$-    else 
#$-    {
#$-    	$fulldir = $BASE_DIR;
#$-    	$webdir = $WEB_BASE_DIR;
#$-    }   
#$-    $backdir = $dir;
#$-    $backdir =~ s!\w*$!!;  # if $dir = /1999/01  then $backdir = /1999/
#$-    $thumbdir = "$fulldir/thumbs";
#$-    $webthumb = "$webdir/thumbs";
#$-
#$-    if ($debug_dirs)
#$-    {
#$-	&printHead;
#$-    	print"<body>";
#$-	print "<br>this = >$THIS_FILE<";
#$-    	print "<br>base = >$BASE_DIR<";
#$-    	print "<br>dir = >$dir<";
#$-    	print "<br>backdir = >$backdir<";
#$-    	print "<br>thumbdir = >$thumbdir<";
#$-    	print "<br>fulldir = >$fulldir<";
#$-    	print "<br>webbase = >$WEB_BASE_DIR<";
#$-    	print "<br>webdir = >$webdir<";
#$-    	print "<br>webthumb = >$webthumb<";
#$-    }
#$-}
#$-
#$-#######################################
#$-#
#$-#  printDirs prints links to all the dirs in @dirs_in_dir plus the parent directory
#$-#
#$-sub printDirs
#$-{
#$-    print "\n\n<p><a href='$THIS_FILE?dir=$backdir'>parent dir</a>\n<br>";
#$-    foreach $subdir (sort @dirs_in_dir) {
#$-	print "<br><a href='$THIS_FILE?dir=$subdir'>";
#$-	if ($dir_info=&getContents("$BASE_DIR/$subdir.txt")) {
#$-	    print "$dir_info</a>\n"; 
#$-	}
#$-	else {
#$-	    $subdir =~ s!.*/(\w*)$!$1!;
#$-	    print "$subdir</a>\n";
#$-	}
#$-    }
#$-}
#$-
#$-
#$-
#$-
#$-
#$-
#$-
#$-
#$-
#$-
#$-
#$-
