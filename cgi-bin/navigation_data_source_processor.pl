#!/usr/bin/perl -w

# THIS CODE MAY BE SUPERCEDED BY db_updater.pl, WHICH IS NEARLY
# DESIGNED TO WRITE navigation_definitions.

##############################################









# this code is supposed to write navigation_definitions that can be
# read by draw_navigation.pl

use strict;
use CGI qw(:all);
# use File::Basename;

# these are given values in setup_navigation.pl, but since this is strict, they must be declared.
my ($NAVIGATION_SOURCE_FILE,$INDEX_DEFINITION_FILE);

# require "setup_navigation.pl";
$NAVIGATION_SOURCE_FILE = "/home/thunderrabbit/setup_journal/navigation_data_source.txt";
$INDEX_DEFINITION_FILE = "/home/thunderrabbit/setup_journal/navigation_definitions.txt";


$INDEX_DEFINITION_FILE .= "test_automagical";

my $last_run_time;  # This will be set to the lat time this was run

print "Content-type: text/html\n\n";
print "<head>\n";
print "</head>\n";
print "<body>\n";

=pod
=cut

    open (NSF, "$NAVIGATION_SOURCE_FILE") or die "Can't open $NAVIGATION_SOURCE_FILE for reading";
    while (<NSF>) {
	my (%name_to_URL,  # the menu item name and the URL it should point to
	    %name_to_date, # the menu item name and the date of the directory it points to
	    @name_queue    # the list of menu names will be printed in this order
	    );
	# skip lines that start with #
	unless (m/^#/) 
	   {   # this bracket set by hand
	       if (m/^\s*$/) {
		   print "<br><br>blank: resetting arrays";
		   undef %name_to_URL;
		   undef %name_to_date;
		   undef @name_queue;
		   next;
	       }
	       my @stuff = split;
	       my $URL = pop(@stuff);
	       my $name = join(' ',@stuff);
	       my $nbsp_name = join('&nbsp;',@stuff);
	       print " the next thing to do here is read the first
    line ofthe paragraph into a special array because it needs to be
    treated differently.  Itmight be smart to actually do a bit more
    preplanning and see ifwe canincorporate 2ndand third and Nth level
    menus with this scheme.
Next we need to handle the writing's order by date thing; this token
    needs to be one token, not three.";
	       print "<br>name: $name # or $nbsp_name # URL = $URL";
	   }
    }
=pod

open (DB_DIRECTORY_LIST, "$image_directory_list") || die "could not open $image_directory_list"; # this list tells what directories we can read
until (<DB_DIRECTORY_LIST> =~ m/WHITELIST/) {}  # skip crap until we get to WHITELIST
until (($_ = <DB_DIRECTORY_LIST>) =~ m/~WHITELIST/) {
    chomp;
    push (@image_directory_array, "$directory_base/$_");  # add to list of directories we will scan recursively
}
close (DB_DIRECTORY_LIST) || die "could not close $image_directory_list";

# end insert into @image_directory_array

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
print "</head>\n";
print "<body>\n";

my ($longest,$longestpath,$longestfilename);  #  will remember the longest of each so we can warn if they are too big for MySQL tables.
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

    foreach (@directory_contents) {
	if(!(($_ eq ".") || ($_ eq ".."))) {
	    if (-d "$directory_to_open/$_") {
		push (@image_directory_array, "$directory_to_open/$_"); 
	    } else {
		# check file extension
		my ($extension) = $_ =~ m/\.*?(\w+)$/;
		$extension = lc($extension);  # convert to lower case

		if ($this_extension_is_okay{$extension}) {
		    # check file update date
		    my ($modify_time, $crap);
		    ($crap,$crap,$crap,$crap,$crap,$crap,$crap,$crap,$crap,$modify_time) = stat "$directory_to_open/$_";

		    if ($modify_time >= $last_run_time) {
			&parse_file("$directory_to_open/$_", $modify_time);
		    }

		} else {
#		    print "<br>skip $directory_to_open/$_";
		}
	    }
	}
    }
}

# only  print these if they have a value.
$longestpath && print "<p>$longestpath<br>is " . length($longestpath) . " characters";
$longestfilename && print "<p>$longestfilename<br>is " . length($longestfilename) . " characters";
$longest && print "<p>$longest<br>is " . length($longest) . " characters";

# not very user friendly way to specify time, so give an example.
$longest || print "<p>Oops. Try <a href=\"/cgi-bin/new_pic_URL_getter.pl?last_run_time="  . (time - (24 * 60 * 60)) . "\">this</a>";

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

=pod

    my ($path,$crap,$filename) = $file =~ m!$directory_base/(([\w\d\-\'\!]*/)*)(([\w\d\-\'\!]*\.)*[\w\d\-\'\!]*)!;
#    my ($path,$crap,$filename) = $file =~ m!$directory_base/((\w*/)*)((\w*\.)*\w*)!;
    my $smurfed = 0;  # will be true if we process the file

    if (length($longestpath) < length($path)) { $longestpath = $path; }
    if (length($longestfilename) < length($filename)) { $longestfilename = $filename; }
    if (length($longest) < (length($path) + length($filename))) { $longest = "$path$filename"; }

#=pod

    # I'm tired and just want to get some shit working, but this code
    # would be cooler if it could tell if big images had thumbnails
    # and indicated such.  for now, I'm just going to say if there is
    # a thumbnail, then there is a big one, and assume the URLs will
    # be the same minus /thumbs

    if($path =~ m!/thumbs/!) {
	
	if($filename =~ m/(jpg|jpeg|gif)$/i) {
	    $smurfed = 1;
	    ## begin print HTML code for thumb and big pic
	    my $path_no_thumbs = $path;
	    $path_no_thumbs =~ s!/thumbs/!/!;
	    print "<table border='1'><tr>\n";
	    print "<td><img src='/images/$path$filename'></td>\n";
	    print "<td><form><input type='text' size='150' onFocus='this.value.select()'";
	    print "value='<a href=\"/images/$path_no_thumbs$filename\">";
	    print "<img src=\"/images/$path$filename\" /></a>'></form></td>";
	    print "</tr></table>";
	    ## end print HTML code for thumb and big pic
	}
    }

    unless ($smurfed) {
	print "<br>$directory_base/<b>$path</b>$filename modified: $Todays_date\n";
    }
#=cut

}
=cut
