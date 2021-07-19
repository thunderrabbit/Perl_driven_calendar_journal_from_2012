#!/usr/bin/perl -w

use strict;
# use File::Basename;

=pod
    With the basic premise that content in public_html will be
    arranged according to the navigation structure that I want people
    to use, this code will scan through that structure and write
    navigation_definitions.txt, which will be subsequently used by
    draw_navigation.pl as it is called by the perl scripts that allow
    users to read files on my site.  As of 2004 Nov 04, I'm thinking
    those files will be journal.pl and nav.pl.  journal.pl (the index
    of which was written by Fred) will be largely unchanged except it
    will be able to handle different journal entry types.  nav.pl will
    look for a file called nav_index.txt in each directory which will
    tell nav.pl how to treat the contents of that directory: how to
    present them, by day or by name or what.
=cut

my $directory_base = "/home/barefoot_rob/public_html";  # all directorying should start here
my $db_directory_list = "/home/barefoot_rob/setup_journal/db_directory_list.txt";  # list of directories that are okay to index (based in $directory_base)
my @db_directory_array;   # directories to scan recursively
my @directory_contents;   # what we find in the directories

my %this_extension_is_okay;  #list of extensions that we allow parsing
$this_extension_is_okay{$_} = 1 for qw(txt comment jpg jpeg gif html shtml htm mov JPG);


=pod
This next section inserts into @db_directory_array the initial
set of directories that we will recursively scan.  The directories
listed in the file $db_directory_list must be listed one per line and
surrounded by WHITELIST and ~WHITELIST tokens.  There is no BLACKLIST
functionality.

example $db_directory_list:

# comments
WHITELIST
directories
to
scan
~WHITELIST

=cut

open (DB_DIRECTORY_LIST, "$db_directory_list") || die "could not open $db_directory_list"; # this list tells what directories we can read
until (<DB_DIRECTORY_LIST> =~ m/WHITELIST/) {}  # skip crap until we get to WHITELIST
until (($_ = <DB_DIRECTORY_LIST>) =~ m/~WHITELIST/) {
    chomp;
    push (@db_directory_array, "$directory_base/$_");  # add to list of directories we will scan recursively
}
close (DB_DIRECTORY_LIST) || die "could not close $db_directory_list";

# end insert into @db_directory_array


=pod
    the hash %journal_regex_type defines how to identify specific
    journal entry types according to their filenames matching a
    specific regular expression.
=cut
    my %journal_regex_type = qw(^_                                                                 private
                                ^\d\dzz                                                            sleepy
                                \!                                                                 excited
                                (soml|state.*?(of|my).*?life)                                      SoML
                                dream                                                              dreams
                                (ultimate|frisbee|centex)                                          ultimate
                                (skate|skating)                                                    skate
                                (yruu|(-|_|\d)rally|con.*con|swuusi|(spring|fall).*conference|lry) YRUU
                                ktru                                                               KTRU                 
                                );
    my %journal_type_ages;  # will store the relative ages of the journal types


print "Content-type: text/html\n\n";
print "<head>\n";
print "</head>\n";
print "<body>\n";
print "<p>I've just realized this code does need to check the files' actual modify date so we can do the sort by last updated stuff on journal.";

my $directory_to_open;   # will take elements from @db_directory_array until the array is empty.
while (@db_directory_array) {

    # the idea now is that I will shove new directories onto this array as I read them and shift them off to scan through them.
    $directory_to_open = shift (@db_directory_array);
    opendir(DIR,$directory_to_open) || die("Cannot open directory $directory_to_open!\n");   # open file with handle DIR
    @directory_contents = readdir(DIR);    # Get contents of directory
    closedir(DIR);    # Close the directory

#    print "<br /> $directory_to_open:";

    # Now go through each item in the directory.  If it's another
    # directory, add it to @db_directory_array so we will scan it
    # later.  If it's a file, then call &db_file_scanner on it if it
    # hasn't been scanned since it was updated.

    foreach (@directory_contents) {
	if(!(($_ eq ".") || ($_ eq ".."))) {
	    if (-d "$directory_to_open/$_") {
		push (@db_directory_array, "$directory_to_open/$_"); 
	    } else {
		# check file extension
		my ($extension) = $_ =~ m/\.*?(\w+)$/;

		if ($this_extension_is_okay{$extension}) {
			&parse_file("$directory_to_open/$_");

		} else {
		    print "<br>skip $directory_to_open/$_";
		}
	    }
	}
    }
}

    foreach my $regex (reverse sort {$journal_type_ages{$a} cmp $journal_type_ages{$b}} keys %journal_type_ages) {
	print "<br>1journal 2$regex <b>$regex</b> $regex /cgi-bin/journal.pl?type=$regex  ....($journal_type_ages{$regex})";
    }
print "<br>";


print "</body>";


sub parse_file {

    my ($file) = @_;


=pod 
    We don't care about $directory_base; it is part of every filename
    by design.  But we do care about the path that comes after
    $directory_base.  This next line snags that path into $path and
    the filename into $filename.  We will examine path to see what
    kind of files we are looking at, and treat them accordingly.
=cut

    # path and filenames may have letters digits, hyphens, apostrophes, or exclamation points

    my ($path,undef,$filename) = $file =~ m!$directory_base/(([\w\d\-\'\!]*/)*)(([\w\d\-\'\!]*\.)*[\w\d\-\'\!]*)!;
    my $smurfed = 0; # will be true if we process the file


    if ($path =~ m!^journal/!) {

	if($filename =~ m/^ls-1R\./) { return; }  # don't parse these; they are for journal.pl

    # snag the file's story date so we can populate the journal index
        my ($yyyy,$mm,$dd) = "$path$filename" =~ m!^journal/(\d\d\d\d)/(\d\d)/_?(\d\d)!;

    foreach my $regex (keys %journal_regex_type) {
	
	if($filename =~ m/$regex/i) {
	    $smurfed = 1;
#	    print "<br><b>$journal_regex_type{$regex}: $path$filename</b>\n";
	    unless ($yyyy) {
		print "<br>deal with more gracefully: $path$filename";
	    } else {
		$journal_type_ages{$journal_regex_type{$regex}} = "$yyyy$mm$dd";
	    }
#	    print "<br><b>$yyyy $mm $dd</b>\n";

	    print "<b><br>actually, we should run Fred's ls-1R code with this sorting code merged inside it.</b>";
	    print "<br>First, let's not require writing to ls-1R.txt.";
# here is where we write code that will  keep track of the allowed dates for each type of journal entry.
# here is where we write code that will  keep track of the allowed dates for each type of journal entry.
# here is where we write code that will  keep track of the allowed dates for each type of journal entry.
# here is where we write code that will  keep track of the allowed dates for each type of journal entry.

	}
    }

    }

    unless ($smurfed) {
#	print "<br>$directory_base/<b>$path</b>$filename modified: $Todays_date\n";
    }
#=cut

    # now start looking for file types according to their names and contents
}
