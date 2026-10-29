use strict;
use warnings;

# Config from setup_journal.pl; $debug from journal.pl. $year, $month and
# $day are the shared globals set by sidebar(): journal.pl reads $day after
# mainbar() returns, so they stay global here.
our ($debug, $journal_base, %journal_regex_type, $www_journal_pl, $between_file_text);
our ($year, $month, $day);

sub mainbar {
    my ($date,$journal_type) = @_;
    my (@list_of_titles, @list_of_hrefs, $filename_counter, $title, $filename, $name_for_href_on_this_page);
    my ($trackback_text,$permalink_text);

    $trackback_text = "trackback";
    $permalink_text = "permalink";

    ($year, $month, $day) = split /\//, $date;
    $debug && print "<p>$date: $year/$month/$day\n\n";
    $debug && print "<br>$journal_type";

    # Defense in depth: neutralize glob metacharacters in the date-derived
    # components before building the pattern, so a value such as "*" or
    # "~user" cannot turn this into a wildcard sweep (e.g. bulk-harvesting
    # private "_"-prefixed entries across a whole year) or a home-directory
    # escape. Legitimate numeric date components are unaffected.
    my $glob_prefix = "$journal_base/$year/$month/$day";
    $glob_prefix =~ s/([\\*?\[\]{}~ ])/\\$1/g;
    my @all_files_for_date = glob("$glob_prefix*");
## end ADDRESSING private entries using security through obscurity

    $debug && print "<p>$journal_base/$year/$month/$day</p>";
    $debug && print "\n\n<pre>" . @all_files_for_date . "</pre>\n\n";

    # prune this list to only files that match regex
    my (@files_for_date, $matching_file);
    foreach my $full_file_path (@all_files_for_date) {
        my ($file_only) = $full_file_path =~ m!/(?:(?:.*?)/)*(.*)!;
        $debug && print "<br>comparing $file_only to !$journal_regex_type{$journal_type}!";
        push(@files_for_date, $full_file_path) if ($matching_file) = $file_only =~ m!$journal_regex_type{$journal_type}!i;
    }

    # print the entries for this day so people can click on links
    print "<p>Entries this day: ";
    foreach my $file (sort @files_for_date) {       # sort puts the files in A..Za..z order
        unless ($file =~ m/.*\.comment~*$/) {      # keep comments from being displayed
            unless ($file =~ m/.*\~$/) {      # keep backups from being displayed
                $debug && print "<br>file is \"$file\"\n";
                ($title) = $file =~ m!.*/_?\d\d(.*)\.(?:html|txt|md)$!;
                $debug && print "<br>title is \"$title\"\n";
# $filename is the filename only with no path info.  This name is sent to comment.pl to hide the path of my filesystem.
                ($filename) = $file =~ m!.*/(\d\d.*\.(?:html|txt|md))$!;
                my $title_no_spaces = $title;
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

    foreach my $file (sort @files_for_date) {       # sort puts the files in A..Za..z order
        unless ($file =~ m/.*\.comment~*$/) {      # keep comments from being displayed
            unless ($file =~ m/.*\~$/) {      # keep backups from being displayed
                                             # print "<! filename: $file >\n";
                my $this_entrys_href = shift @list_of_hrefs;
                print ("<a name=\"", $this_entrys_href, "\"></a>\n");
                my $this_entrys_title = shift @list_of_titles;
                print ("<p class=\"entry_title\">", $this_entrys_title, "</p>\n");

                my $istext = ($file =~ m/\.txt$/i) ? 1 : 0;
                my $ismd   = ($file =~ m/\.md$/i) ? 1 : 0;

                # process file with markdown if it's a markdown file
                if ($ismd) {
                    eval {
                        require Text::RobMiniMarkdown;
                        my $md = Text::RobMiniMarkdown->new;
                        my $markdown_content = do {
                            local $/;
                            open my $fh, '<', $file or die "Could not open $file: $!";
                            <$fh>;
                        };

                        my $md_text = $md->markdown($markdown_content);
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
                    if (open(my $fh, '<', $file)) {
                        while (<$fh>) {
                            print;
                        }
                        close $fh;
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
