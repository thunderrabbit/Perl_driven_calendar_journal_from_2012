$style = "/journal/journal/style.css";       # this is used in draw_header.pl
$journal_pl = "/journal/journal.pl";
$www_journal_pl = "http://www.robnugen.com/journal$journal_pl";
$journal_base = "/home/barefoot_rob/robnugen.com/journal/journal";    # first journal is Perl; second are entries with backwards story
$quicklist_file = "/home/barefoot_rob/robnugen.com/quicklist_for_journal.txt";
$journal_log_file = "/home/barefoot_rob/robnugen.com/safe/journal_log.txt";
$between_file_text = "<hr />";  # printed between files on mainbar

=pod
    the hash %journal_regex_type defines how to identify specific
    journal entry types according to their filenames matching a
    specific regular expression.
    # Here is the regex for private entries \b_\d\d.*?\..*\b
=cut

%journal_regex_type = qw(all      ^\d\d.*?
			 sleepy   ^\d\dzz.*?
			 excited  ^\d\d.*?!.*
			 SoML     ^\d\d.*?(?:soml|state.*?(?:of|my).*?life).*
			 dreams   ^\d\d.*?dream.*
			 gateway  ^\d\d.*?gateway_data.*
			 runes    ^\d\d.*?(?:rune|runes).*
			 ultimate ^\d\d.*?(?:ultimate|frisbee|centex).*
			 skate    ^\d\d.*?(?:skate|skating).*
			 YRUU     ^\d\d.*?(?:yruu|(?:-|_|\d)rally|con.*con|swuusi|(?:spring|fall).*conference|lry).*
			 KTRU     ^\d\d.*?ktru.*
			 nihongo  ^\d\d.*?nihongo.*
			 privvy   ^_\d\d.*?
			 );

