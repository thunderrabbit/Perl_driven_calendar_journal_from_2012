$style = "/journal/style.css";       # this is used in draw_header.pl
$journal_pl = "/journal.pl";
$www_journal_pl = "http://perl.robnugen.com$journal_pl";
$comment_pl = "/comment_sender_for_my_homies.pl";
$comment_pl = "/comment_sender2Boi.pl";  # 2Bo to stop spam  # Ctrl-x d comment_sender.pl to stop spam.   delete this line/file altogether to stop anonymous comments
$journal_base = "/home/dh_r2ixxd/perl.robnugen.com/journal";
$quicklist_file = "/home/dh_r2ixxd/perl.robnugen.com/quicklist_for_journal.txt";
$journal_log_file = "/home/dh_r2ixxd/perl.robnugen.com/safe/journal_log.txt";
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

