sub mainbar {
    my ($date,$journal_type) = @_;
    my (@list_of_titles, @list_of_hrefs, $filename_counter, $title, $filename, $name_for_href_on_this_page);
    my ($trackback_text,$permalink_text);

    $trackback_text = "trackback";
    $permalink_text = "permalink";

    ($year, $month, $day) = split /\//, $date;
    $debug && print "<p>$date: $year/$month/$day\n\n";
    $debug && print "<br>$journal_type";

	@all_files_for_date = <$journal_base/$year/$month/$day\*>;
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
				($title) = $file =~ m!.*/_?\d\d(.*)\.(?:html|txt|md)$!;
				$debug && print "<br>title is \"$title\"\n";
				# $filename is the filename only with no path info.  This name is sent to comment.pl to hide the path of my filesystem.
				($filename) = $file =~ m!.*/(\d\d.*\.(?:html|txt|md))$!;
				$title_no_spaces = $title;
				$title_no_spaces =~ s/_/ /g;  # basically the title of the entry

				# Fixes #9, but a better fix is #8 get title from Frontmatter if this is a markdown file
				$title_no_spaces =~ s/-/ /g;  # Markdown files have hyphens like this

				push (@list_of_titles, $title_no_spaces);

				$name_for_href_on_this_page = $title;
				push (@list_of_hrefs, $name_for_href_on_this_page);  # append title + sequence number to the list

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
				print ("<p class=\"entry_title\">", $this_entrys_title, "</p>\n");

				my $istext = 1  if ($file =~ m/\.txt$/i);
				my $ismd   = 1  if ($file =~ m/\.md$/i);

				# process file with markdown if it's a markdown file
				if ($ismd) {
					eval {
						require Text::RobMiniMarkdown;
						$md = Text::RobMiniMarkdown->new;
						my $markdown_content = do {
							local $/;
							open my $fh, '<', $file or die "Could not open $file: $!";
							<$fh>;
						};

						$md_text = $md->markdown($markdown_content);
						if ($md_text) {
							print $md_text;
						} else {
							print "<p>!-- Markdown parser returned nothing for $file --\n</p>";
						}
					1;
					} or do {
						my $error = $@ || 'Unknown error';
						print "<pre>Markdown processing error: $error</pre>\n";
					};
				}
				else {
				print "<pre>\n" if ($istext);
				if (open (FILE, "$file")) {
					while(<FILE>) {
						print;
					}
					close FILE;
				}
				print "</pre>\n" if ($istext);
				}

				print <<permaLINK;
<a href="$www_journal_pl?type=$journal_type&amp;date=$date#$this_entrys_href">$permalink_text</a>
permaLINK

				print "$between_file_text";
			}
		}
    }
}
1;
