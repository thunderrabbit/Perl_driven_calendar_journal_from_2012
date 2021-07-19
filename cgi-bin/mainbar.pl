sub mainbar {
    my ($date,$journal_type) = @_;
    my (@list_of_titles, @list_of_hrefs, @list_of_filenames, $filename_counter, $title, $filename, $name_for_href_on_this_page);
    my ($comment_text,$trackback_text,$permalink_text);

    $comment_text = "comment";  # what text is displayed on screen for comments
    $trackback_text = "trackback";
    $permalink_text = "permalink";

    ($year, $month, $day) = split /\//, $date;
    $debug && print "<p>$date: $year/$month/$day\n\n";
    $debug && print "<br>$journal_type";

    my ($name,$email);
##  ADDRESSING private entries using security through obscurity
    ##   This code has been stolen from print_comment_form
    {
	local (%cookies_read);
	%cookies_read = fetch CGI::Cookie;

	$name=$cookies_read{'name'} -> value if ($cookies_read{'name'});
	$email=$cookies_read{'email'} -> value if ($cookies_read{'email'});
    }

    if (($ENV{"REMOTE_ADDR"} eq "123.222.26.160") && ($journal_type eq "privvy")) {
	@all_files_for_date = <$journal_base/$year/$month/_$day\*>;
    } else {
	# this doesn't get private files because they start with _ and therefore won't match "/$day*"
	@all_files_for_date = <$journal_base/$year/$month/$day\*>;
    }
## end ADDRESSING private entries using security through obscurity

    $debug && print "<p>$journal_base/$year/$month/$day</p>";
    $debug && print "\n\n<pre>" . @all_files_for_date . "</pre>\n\n";

    # prune this list to only files that match regex
    foreach $full_file_path (@all_files_for_date) {
	my ($file_only) = $full_file_path =~ m!/(?:(?:.*?)/)*(.*)!;
	$debug && print "<br>comparing $file_only to !$journal_regex_type{$journal_type}!";
	push(@files_for_date, $full_file_path) if ($matching_file) = $file_only =~ m!$journal_regex_type{$journal_type}!i;
    }

    # print the entries for this day so people can click on links
    print "<p>Entries this day: ";
    foreach $file (sort @files_for_date) {       # sort puts the files in A..Za..z order
	unless ($file =~ m/.*\.comment~*$/) {      # keep comments from being displayed
	    unless ($file =~ m/.*\~$/) {      # keep backups from being displayed
		$debug && print "<br>file is \"$file\"\n";
		($title) = $file =~ m!.*/_?\d\d(.*)\.(?:html|txt)$!;
		$debug && print "<br>title is \"$title\"\n";
		# $filename is the filename only with no path info.  This name is sent to comment.pl to hide the path of my filesystem.
		($filename) = $file =~ m!.*/(\d\d.*\.(?:html|txt))$!;
		$title_no_spaces = $title;
		$title_no_spaces =~ s/_/ /g;  # basically the title of the entry
		push (@list_of_titles, $title_no_spaces);

		$name_for_href_on_this_page = $title;
		push (@list_of_hrefs, $name_for_href_on_this_page);  # append title + sequence number to the list

		push (@list_of_filenames, "$year/$month/$filename"); # put filename on stack.  used for comment.pl
		print "<a href=\"#$name_for_href_on_this_page\">$title</a>\n";
	    }
	}
    }
    print "</p> <!-- matches Entries this day: -->\n";

    foreach $file (sort @files_for_date) {       # sort puts the files in A..Za..z order
	unless ($file =~ m/.*\.comment~*$/) {      # keep comments from being displayed
	    unless ($file =~ m/.*\~$/) {      # keep backups from being displayed
		# print "<! filename: $file >\n";
		$this_entrys_href = shift @list_of_hrefs;
		print ("<a name=\"", $this_entrys_href, "\"></a>\n");
		$this_entrys_title = shift @list_of_titles;
		print ("<p class=\"entry_title\">", $this_entrys_title , "</p>\n");
      
    my $istext = 1  if ($file =~ m/\.txt$/i);
    my $ismd   = 1  if ($file =~ m/\.md$/i);
      
		print "<pre>\n" if ($istext || $ismd);  
		if (open (FILE, "$file")) {
		  while(<FILE>) {
		      print;
		  }
      close FILE;
    }
		print "</pre>\n" if ($istext || $ismd);

		# print a link to allow comments
		$filename = shift @list_of_filenames;

		##   This code has been stolen from print_comment_form
		##  We want to allow only cool people to use the cool comment form.
		{
		    local (%cookies_read);

		    %cookies_read = fetch CGI::Cookie;

		    if ($cookies_read{'name'}) {
			$name=$cookies_read{'name'} -> value;
		    } else {
			$name = "";
		    }

		    if ($cookies_read{'email'}) {
			$email=$cookies_read{'email'} -> value;
		    } else {
			$email = "";
		    }
		    
		    # These top few lines aren't needed to keep out anonymous commenters, but are added to make the code a bit faster
		    if ($name eq "" || $email eq "") {
			$use_cool_comment_form = "NO";
		    } elsif (
# I want these lines to be written in cool_commenters.pl by the comment_for_my_buds.pl file
# and then have them directly imported here.
# ($name eq "
# " && $email eq "\@
# ") ||

			     ($name eq "rob" && $email eq "rob\@robnugen.com") ||
			     ($name eq "j" && $email eq "janettebibby\@lycos.com") ||
			     ($name eq "Ma" && $email eq "ellisfile2\@yahoo.com") ||
			     ($name eq "Maggie" && $email eq "spiderman\@usdataworks.com") ||
			     ($name eq "Jesse" && $email eq "jessecesario\@hotmail.com") ||
			     ($name eq "Olivier LARRIEU" && $email eq "olivla\@hotmail.com") ||
			     ($name eq "TinaP" && $email eq "orbandprincess\@aol.com") ||
			     ($name eq "tinason orbandprincess\@aol.com" && $email eq "orbandprincess\@aol.com") ||
			     ($name eq "annie" && $email eq "misfortunatedonkey\@hotmail.com") ||
			     ($name eq "Jennifer" && $email eq "projectthis\@hotmail.com") ||
			     ($name eq "Jimmy de Guzman" && $email eq "sponty\@hotmail.com") ||
			     ($name eq "Ricky" && $email eq "problimaticboy\@hotmail.com")
			     ) {
			$use_cool_comment_form = "YES";
		    }
		}
## 2004 Sept 30:
## I'm allowing everyone to use the cool comment form again.
## to disable, remove the following line and change $comment_pl in setup
### 2007 September 13: killed it again

		$use_cool_comment_form = "NOPE";
		if ($use_cool_comment_form eq "YES") {
		    print "<a href=\"$comment_pl?file=$filename&amp;date=$date\">$comment_text</a>\n";
		} else {
		    my $email_to = $filename;
		    $email_to =~ s|/|\.|g;
		    print "<a href=\"mailto:$email_to\@robnugen.com\">$comment_text</a>\n";
		}

    print <<permaLINK;
| <a href="$www_journal_pl?type=$journal_type&amp;date=$date#$this_entrys_href">$permalink_text</a>
permaLINK

	    print "$between_file_text";
	    }
	}
    }
}
1;
