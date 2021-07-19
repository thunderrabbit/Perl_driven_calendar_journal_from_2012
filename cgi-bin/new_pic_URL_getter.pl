#!/usr/bin/perl -w

use strict;
use CGI qw(:all);
# use File::Basename;

use mkdef;
my $directory_base = "/home/barefoot_rob/temp.robnugen.com/images";  # all directorying should start here
my $last_pic_URLs_snagged = "/home/barefoot_rob/settings/last_new_pic_URLs_snagged.txt";   # file to remember when this code was last run
my @image_directory_array;   # directories to scan recursively
my @directory_contents;   # what we find in the directories

my $old_path_no_thumbs;  # added May 2006: print the path each time it changes

my %this_extension_is_okay;  #list of extensions that we allow parsing
$this_extension_is_okay{$_} = 1 for qw(png txt jpg jpeg gif);

my $last_run_time = 0;  # This will be set to the lat time this was run
my $num_images_per_row = 5; # how many images across to display
my $imageCount = 0;

# Seed @image_directory_array the parent directory of directories that we will recursively scan.
@image_directory_array = ("$directory_base");

do {
#    This code should not be run on files that have not been modified
#    since this code ran last time.  So we read the last run time from
#    $last_pic_URLs_snagged

    my $query = new CGI;
    unless ($last_run_time = $query->param('last_run_time')) {

	# read $last_run_time from file; it was not given in URL
	open(DB_LAST_RUN, "$last_pic_URLs_snagged")  || 
	    die "db_updater could not open $last_pic_URLs_snagged for read";
	$last_run_time = <DB_LAST_RUN>;
	chop $last_run_time;
	close(DB_LAST_RUN);
    }
};

print "Content-type: text/html\n\n";
print "<head>\n";
print "<script src='/js/AJAX.js'  type='text/javascript'></script>\n";
print "</head>\n";
print "\n<body>\n";

my $directory_to_open;   # will take elements from @image_directory_array until the array is empty.
while (@image_directory_array) {

    # the idea now is that I will shove new directories onto this array as I read them and shift them off to scan through them.
    $directory_to_open = shift (@image_directory_array);




    opendir(DIR,$directory_to_open) || die("Cannot open directory $directory_to_open!\n");   # open file with handle DIR
    @directory_contents = readdir(DIR);    # Get contents of directory
    closedir(DIR);    # Close the directory

#    print "<br /> $directory_to_open:";

    # Now go through each item in the directory.  If it's another
    # directory, add it to @image_directory_array so we will scan it
    # later.  If it's a file, then call &db_file_scanner on it if it
    # hasn't been scanned since it was updated.

    foreach (@directory_contents) 
    {
	if(!(($_ eq ".") || ($_ eq ".."))) 
	{
	    if (-d "$directory_to_open/$_") 
	    {
		push (@image_directory_array, "$directory_to_open/$_"); 
	    } 
	    else 
	    {
		# check file extension
		my ($extension) = $_ =~ m/\.*?(\w+)$/;
		$extension = lc($extension);  # convert to lower case

		if ($this_extension_is_okay{$extension}) 
		{
		    # check file update date
		    # Rob: just for the record: you have tried putting this check on the directory push above, but it simply doesn't work.  All the parent dirs aren't updated.
		    my ($modify_time, undef) = (0);
		    (undef,undef,undef,undef,undef,undef,undef,undef,undef,$modify_time) = stat "$directory_to_open/$_";

		    if (&mkdef($modify_time) >= $last_run_time) {
			&parse_file("$directory_to_open/$_", $modify_time);
		    }

		} else {
#		    print "<br>skip $directory_to_open/$_";
		}
	    }
	}
    }
}

# This writes a final end-row / table tag if we didn't have a full final row.
if($imageCount % $num_images_per_row) {
    print "</tr></table>\n";
}

# We don't use a very user friendly way to specify time, so give examples.
print "\n<p>Start this number of days ago:\n";

foreach my $day_counter (0, 1, 2, 3, 4, 5, 6, 7, 10, 14, 30, 45, 60, 80, 90, 120, 130, 140, 150, 160, 180, 200) {
    print "<br><a href=\"/cgi-bin/new_pic_URL_getter.pl?last_run_time="  . (time - ($day_counter * 24 * 60 * 60)) . "\">$day_counter days ago</a>\n";
}

print "</body>";

do {
#  this is the very last thing we do

#    This code should not be run on files that have not been modified
#    since this code ran last time.  So we save the last run time in
#    $last_pic_URLs_snagged

    my @month_name = qw (January February March April May June July
			 August September October November December);
    my @day_name = qw (Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
    
    my  $now = time;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($now);
    my $Todays_date = "$hour:$min:$sec GMT $day_name[$wday] $mday $month_name[$mon] " . ($year + 1900);
    
    open(DB_LAST_RUN, ">$last_pic_URLs_snagged")  || die "db_updater could not open $last_pic_URLs_snagged";
    print DB_LAST_RUN "$now\n";
    print DB_LAST_RUN "$Todays_date\n";
    close(DB_LAST_RUN);

    print "\n<p>Last run:\n<br>$Todays_date</p>\n";
};


sub parse_file {

    my ($file,$modify_time) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($modify_time);
    my $Todays_date = ($year + 1900) . "/" . ($mon + 1) . "/$mday";

=pod
    We  don't care about $directory_base; it is part of every filename by design.
    But we do care about the path that comes after $directory_base.
    This next line snags that path into $path and the filename into
    $filename.  We will examine path to see what kind of files we are
    looking at, and treat them accordingly.
=cut

    my ($path,undef,$filename) = $file =~ m!$directory_base/(([\w\d\-\'\!]*/)*)(([\w\d\-\'\!]*\.)*[\w\d\-\'\!]*)!;
    my $smurfed = 0;  # will be true if we process the file

    # I'm tired and just want to get some shit working, but this code
    # would be cooler if it could tell if big images had thumbnails
    # and indicated such.  

    # ORIGINALLY: for now, I'm just going to say if there is
    # a thumbnail, then there is a big one, and assume the URLs will
    # be the same minus /thumbs

    # SEPTEMBER 2005: if it ends with thumbs or Thumbnails, then
    # assume there is a big picture and create big picture URL
    # accordingly.

    if($path =~ m!(/thumbs|-Thumbnails)/!i) {
	
	if($filename =~ m/(png|jpg|jpeg|gif)$/i) 
	{
	    $smurfed = 1;
	    ## begin print HTML code for thumb and big pic
	    my $path_no_thumbs = $path;
	    if($path =~ m!/thumbs/!) {
		$path_no_thumbs =~ s!/thumbs/!/!;
	    }
	    elsif($path =~ m!Thumbnails/!)
	    {
		$path_no_thumbs =~ s!-Thumbnails/!!;
		$path_no_thumbs = $path_no_thumbs . "-Images/";
	    }
	    else
	    {
		$path_no_thumbs =~ s!-thumbnails/!!;
		$path_no_thumbs = $path_no_thumbs . "-images/";
	    }
	    $imageCount ++;

	    if (($path_no_thumbs ne $old_path_no_thumbs) && ($imageCount % $num_images_per_row)) {
		print "</tr></table>\n";
	    }


	    unless (($path_no_thumbs eq $old_path_no_thumbs) && (($imageCount - 1) % $num_images_per_row)) {
		print "$path_no_thumbs:";
		print "\n<table border='1'><tr>\n";
	    }
	    print "<td id='toc$imageCount' align='left' valign='top'>\n";
	    print "<div id='toctitle$imageCount'>\n";
	    print "</div>\n";
	    print "$filename";
	    print "<a href=\"/images/$path_no_thumbs$filename\"><img src=\"/images/$path$filename\" /></a>\n";
	    print "<form><input type='text' size='15' onFocus='this.select();' ";
	    print "value='<a href=\"/images/$path_no_thumbs$filename\">";
	    print "<img src=\"/images/$path$filename\" /></a>'></form></td>\n";
	    print "<script type='text/javascript'>\n";
	    print " if (window.showTocToggle) { var tocShowText = 'O'; var tocHideText = 'o'; showTocToggle($imageCount); } \n";
	    print "</script>\n";
	    unless ($imageCount % $num_images_per_row) {
		print "</tr></table>\n";
	    }
	    $old_path_no_thumbs = $path_no_thumbs;
	    ## end print HTML code for thumb and big pic
	}
    }

    unless ($smurfed) {
#	print "<br>$directory_base/<b>$path</b>$filename modified: $Todays_date\n";
    }
#=cut

}

