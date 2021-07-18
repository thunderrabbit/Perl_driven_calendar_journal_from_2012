#!/usr/bin/perl -w

# this code stolen from gaba_tracker.pl on 2005 Feb 10, and I tried to fuck with it but I'm drowning in code and sleepiness
# the idea is to record and rate funny calculator game entries
# http://www.google.com/search?q=hectoliter+%2F+month+in+acre+foot+%2F+millenium

use strict;
use CGI qw(:all fatalsToBrowser);
use CGI::Cookie;
use DBI;
use HTML::PullParser;
use Slurper;
require "setCookies.pl";  # a proven method to write cookies; I'm not sure how to do it with straight CGI objects.

my $this_pl =  $ENV{'SCRIPT_NAME'};
my $detail_debug_on = 0;
my $debug_on = 1;

my $query = new CGI;
my %cookie; # this is a hash of cookies with which we'll store instructorID and instructorPW

my $serverHostname = "db1.webquarry.com";
my $serverUsername = "rob";
my $serverPassword = "sorry; I don't want this available";   # if I want to store the entries, need to block source viewing with source_viewer.pl or other solution
my $serverDatabase = "rob";

my $Main_Body_Output = "";    # this will store the html source of the main part of the window
my $Button_Output = "";       # this will store the html source of the navigation
my $Next_Action = "";         # will keep track of what we're supposed to do
my $debug_msg = "\n<p>Debug in progress.  Code may break, etc.\n" if ($debug_on);           # for debugging
my $detail_debug_msg;
my $title = "Google Calculator Game by DR F";
my @list_of_buttons = qw(try topscores scoring);
my $URL_request_for_google; # will store what we send to google
my $googles_calculation;  # will store what google returns in calculator thing
my $userID_logged_in = "";

# First thing we do is check the credentials of whoever is using the system
&check_authentication;

my $loop_detector = 0;
while (1) {

    if ($loop_detector++ > 5) {
	$detail_debug_msg .= "<br>\$Next_Action is <b>$Next_Action</b>, but a <b>loop was detected</b>.  Buh-bye.";
	die "Loop detected.  Killing process";
    }
    if ($Next_Action eq "finished") {
	&end_processing;
	last;
    }
    if ($Next_Action eq "look for input") {
	&look_for_input_data;
    }
    if ($Next_Action eq "display default screen") {
	&display_default_screen;
    }
    if ($Next_Action eq "display topscores") {
	&display_top_scores;
    } 
    if ($Next_Action eq "process raw string") {
	&process_raw_string;
    }
    if ($Next_Action eq "print results of this entry") {
	&print_results_of_this_entry;
    }
    if ($Next_Action eq "calculate score for this entry") {
	&calculate_score_for_this_entry;
    }
    if ($Next_Action eq "display score for this entry") {
	&display_score_for_this_entry;
    }
}

sub display_score_for_this_entry {
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}
    $debug_msg = "\n<p>pretending to display a score for <b>$googles_calculation</b>";
    $Next_Action = "finished";
}

sub calculate_score_for_this_entry {

    my @number_array;
    my %unit_hash;
    my $number_total;
    my $ecogc = $googles_calculation;  # ecogc = expendable copy of googles calculation

    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}
    $debug_msg = "\n<p>pretending to calculate a score for <b>$googles_calculation</b>";

    $ecogc =~ s!<font size=-2> </font>!!g;  # these tags make spaces in long numbers
    $detail_debug_msg .= "\n<p>removed font tags from <b>$ecogc</b></p>";

    &get_all_the_scientific_notation_numbers(\@number_array,\$ecogc);
    &get_all_the_other_numbers(\@number_array,\$ecogc);

    foreach (@number_array) {
	$debug_msg .= "<br>extracted: $_\n";
	$number_total += ($_ < 0) ? (0-$_) : $_;
    }

    # subtract 1 for the unit value in front.
    $number_total -= 1;

    # find the difference between the result and 1.
    $number_total = ($number_total < 1) ? 1 - $number_total : $number_total - 1;
	
    $debug_msg .= "\n<p>This is the absolute valued total away from 1: $number_total</p>\n";

    &get_unique_units(\%unit_hash,\$ecogc);

    $Next_Action = "display score for this entry";
}

sub get_unique_units {
    my ($unit_hash_pointer,$ecogc_pointer) = @_;


    # first compress two-word units into one word strings
    $$ecogc_pointer =~ s!US !US!ig;
    $$ecogc_pointer =~ s!British !British!ig;
    $$ecogc_pointer =~ s!Metric !Metric!ig;

    # get rid of 'square' cause it's not a unit and could be used to cancel a non-squared version
    $$ecogc_pointer =~ s!square !!ig;

    my $REGEX_to_extract_units = qr {
	([\w]+)
	}ix;

    my @units;
    @units = $$ecogc_pointer =~ m!$REGEX_to_extract_units!g;
    $debug_msg .= "\n<p><b> THIS DOES NOT RETURN UNITS IN ANY USEFUL WAY.  NEED TO DECIDE WHICH FUNCTION WILL COUNT THE UNITS AND WHICH FUNCTION WILL STORE THE UNITS, ETC.</b></p>\n";
    $debug_msg .= "\n<p>Found " . join(':',@units) . "</p>\n";

    $debug_msg .= "\n<p>ecogc is still \"$$ecogc_pointer\"</p>\n";
    $$ecogc_pointer =~ s!$REGEX_to_extract_units!!g;
    $debug_msg .= "\n<p>Now ecogc is \"$$ecogc_pointer\"</p>\n";
}


sub get_all_the_other_numbers {
    my ($num_array_pointer,$ecogc_pointer) = @_;
    my $number;

    my $REGEX_to_extract_numbers = qr {
	([-+]?\s*[\d\.]+)
	}ix;

    push(@$num_array_pointer,$$ecogc_pointer =~ m!$REGEX_to_extract_numbers!g);
    $detail_debug_msg .= "\n<p>Found " . join(':',@$num_array_pointer) . "</p>\n";

    $detail_debug_msg .= "\n<p>ecogc is still \"$$ecogc_pointer\"</p>\n";
    $$ecogc_pointer =~ s!$REGEX_to_extract_numbers!!g;
    $debug_msg .= "\n<p>Now ecogc is \"$$ecogc_pointer\"</p>\n";
}

sub get_all_the_scientific_notation_numbers {
    my ($num_array_pointer,$ecogc_pointer) = @_;
    my ($float,$multiplier,$base,$exponent);
    my @scientific_number_pieces;

    my $REGEX_to_extract_scientific_notation = qr{  # quoted regular expression
	([-+]?\s*[\d\.]+)\s*           # MULTIPLIER: optional preceeding sign and integer or float
	(?:e|                          # e or the next 4 lines
	(?:&times;|x)*\s*              # X  (we ignore case)
	\(?                            # optional open paren
	([-+]?\s*[\d\.]*)\s*           # BASE: optional preceeding sign and integer or float
	(?:<sup>|\^)\s*                # ^  to the power of
	)                              # close e
	([-+]?\s*[\d\.]+)\s*           # EXPONENT: optional preceeding sign and integer or float
	(?:</sup>)?                    # match close </sup> or nothing
	\)?                            # optional close paren
    }ix;                               # ignore case   multi-line mode

    @scientific_number_pieces = $$ecogc_pointer =~ m!$REGEX_to_extract_scientific_notation!g;

    # if there are numbers in this array, snag them off and see what they are
    while ($#scientific_number_pieces > 1) {
	$exponent   = &mkdef(pop(@scientific_number_pieces));
	$base       = &mkdef(pop(@scientific_number_pieces));
	$multiplier = &mkdef(pop(@scientific_number_pieces));

	$base = 10 unless ($base);   # if the base is e, then change it to 10

	# calculate what we pulled off the stack
	$float = $multiplier * ($base ** $exponent);

	# push it onto the main:: number stack
	push(@$num_array_pointer,$float);
	$detail_debug_msg .= "<br>found $float = $multiplier  ($base  $exponent)";
	if ($loop_detector++ > 10) {
	    $debug_msg .= "<br>Inside the scientific number extractor, a <b>loop was detected</b>.  Buh-bye.";
	    last;
	}
    }
    $detail_debug_msg .= "\n<p>ecogc is still \"$$ecogc_pointer\"</p>\n";

    # remove all the parts that were matched before
    $$ecogc_pointer =~ s!$REGEX_to_extract_scientific_notation!!g;
    $debug_msg .= "\n<p>Now ecogc is \"$$ecogc_pointer\"</p>\n";

}

sub display_default_screen {
    print $query->header, $query->start_html("$title");
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}
    &display_buttons("try");
    &display_calc_string_entry_form;
    print $query->end_html;
    $Next_Action = "finished";  # do nothing else this run
}


sub display_buttons {
    my $which_button = shift;
    my $button_html;

    foreach (@list_of_buttons) {
	$button_html = "";
	if ($_ eq $which_button) {
	    $button_html .= $query->b($_) . " ";
	} elsif ($_ eq "try") {
	    $button_html .= $query->a({-href=>"$this_pl?m=try"}, "try")  . " ";
	} elsif ($_ eq "topscores") {
	    $button_html .= $query->a({-href=>"$this_pl?m=topscores"}, "top scores") . " ";
	}
	print $button_html;
    }
}
    
sub display_calc_string_entry_form {
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}
    print $query->p( $query->start_form("GET"), 
		     $query->textfield(-name=>'q',-size=>80,-value=>"m/s in feet/hour"),
		     "\n", $query->br,
		     $query->submit(-name=>'m', -value=>'calculate'),
		     $query->end_form
		     );
}

sub display_top_scores {
    print $query->header, $query->start_html("$title");
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}

    &display_buttons("topscores");
    print $query->p( $query->a({-href=>"http://www.google.com/search?q=hectoliter+%2F+month+in+acre+foot+%2F+millenium", -target=>"_blank"},
			       "1 hectoliter / month = 0.972855833 (acre foot) / millenium"),
		     "Score = 147.36131 by Dude"
		     );
    print $query->p( $query->a({-href=>"http://www.google.com/search?q=stone+%2F+%28square+microns%29+*+ml+%2F+ton+%2F+league", -target=>"_blank"},
			       "1 (stone / (square microns)) * ((ml / ton) / league) = 1.25989921"),
		     "Score = 19.238227 by Rob"
		     );
    print $query->end_html;

    $Next_Action = "finished";  # do nothing else this run
}

sub print_results_of_this_entry {
    print $query->header, $query->start_html("$title");
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}

    &display_buttons("try");
    &display_calc_string_entry_form;
    if($googles_calculation eq 0) {
	print $query->p("Google didn't invoke calculator for ",
			$query->a({-href=>"$URL_request_for_google", -target=>"_blank"},
				  "your entry"),
			"."
			);
	$Next_Action = "finished";
    } else {
	print $query->p( "$googles_calculation"  );
	$Next_Action = "calculate score for this entry";
    }
    print $query->end_html;
}

sub process_raw_string {

    my $START_TOKEN_PREFIX = "START:";   # these three are used by PullParser
    my $END_TOKEN_PREFIX = "END:";
    my $START_TEXT_PREFIX = "TEXT:";

    my $full_url = $ENV{'REQUEST_URI'};   # the URL (URI) contains the exact string we need to send to google
    my ($entry_string) = $full_url =~ /(q=[^&]*)/;  # the exact string we need to send to google is here
    $URL_request_for_google = "http://www.google.com/search?" . $entry_string;

    my $GOOGLES_calculator_image = "/images/calc_img.gif";
    my $found_calculator_image = 0;

    $debug_msg .= $query->p("sending <b>$URL_request_for_google</b> to google.");

    my $google_response = &slurpURL($URL_request_for_google);

    my $p = HTML::PullParser->new 
  	( doc => $google_response,
  	  report_tags => [qw(font img b sup)],                    # only care about these tags
	  # below, we tell what to return when start tags, end tags, and pure text are found.
	  # tagname is the name of the tag.  attr is a hash of the attributes of the tag.  text is source text (including markup)
          # the last text parameter is used when piecing together the result from google (look for $$token[3])
  	  start => "'$START_TOKEN_PREFIX', tagname, attr,  text", 
  	  end =>   "'$END_TOKEN_PREFIX',   tagname, undef, text", 
  	  text =>  "'$START_TEXT_PREFIX',  text,    undef, text"  
	  );

    $p->unbroken_text( 1 );   # make sure text is returned all at once

    # Look for the image of the calculator.  Once we find it, we are quite close to the result we want.
    # if there is no calculator image, then google didn't invoke calculator
    # BUG: if someone sends a query that results in the calculator image being served, this code will likely fail.
    while (my $token = $p->get_token) {
	if ($$token[1] eq "img") {
	    if (&mkdef(${$$token[2]}{'src'}) eq "$GOOGLES_calculator_image") {
		$found_calculator_image = 1;
		last;
	    }
	}
    }

    if ($found_calculator_image) {
	# the text we want is between the <b> </b> tags.  There may be a <sup></sup> tag pair in there.

	# Look for the first <b> tag
	while (my $token = $p->get_token) {
	    if ($$token[0] eq "$START_TOKEN_PREFIX" && $$token[1] eq "b") {
		last;
	    }
	}

	# We found the first <b> tag; snag everything until the </b> tag.
	while (my $token = $p->get_token) {
	    unless ($$token[0] eq "$END_TOKEN_PREFIX" && $$token[1] eq "b") {
		$detail_debug_msg .= "<br>$$token[0] $$token[1]<br>";
		$googles_calculation .= $$token[3]; # $$token[3] is the unmodified text of the token, including markup
	    } else {
		last;
	    }
	}
    } # if $found_calculator_image
    else {
	$detail_debug_msg .= "Google didn't use calculator on this.";
	$googles_calculation = 0
    }
    $Next_Action = "print results of this entry";
}

sub end_processing {
    if ($debug_on) {print "$debug_msg";    $debug_msg = "";}
    if ($detail_debug_on) {print "$detail_debug_msg";    $detail_debug_msg = "";}
    $Next_Action = "finished";
}

# don't drown  # This one might benefit from handling printreport ___, using the second token as a parameter
# don't drown  if ($Next_Action eq "processdata who") {
# don't drown      &processdata_who;
# don't drown      $Next_Action = "printreport who";
# don't drown  } elsif ($Next_Action eq "add instructor to db") {
# don't drown      &processdata_add_instructor;
# don't drown      $Next_Action = "create button html";
# don't drown  } elsif ($Next_Action eq "add choices to db") {
# don't drown      &processdata_add_choices;
# don't drown      $Next_Action = "printreport who";
# don't drown  } elsif ($Next_Action eq "add reminder to db") {
# don't drown      &processdata_add_reminder;
# don't drown      $Next_Action = "printreport who";
# don't drown  }
# don't drown  
# don't drown  
# don't drown  if ($Next_Action eq "printreport who") {
# don't drown      &printreport_who;
# don't drown      $Next_Action = "create button html";
# don't drown  } elsif ($Next_Action eq "draw add instructor screen") {
# don't drown      &write_add_instructor_screen;
# don't drown      $Next_Action = "create button html";
# don't drown  } elsif ($Next_Action eq "draw add reminder screen") {
# don't drown      &write_add_reminder_screen;
# don't drown      $Next_Action = "create button html";
# don't drown  } elsif ($Next_Action eq "complain about invalid data") {
# don't drown      $Main_Body_Output .= "<br>I don't know how to process the data you entered";
# don't drown      $Next_Action = "print default screen";
# don't drown  }
# don't drown  
# don't drown  if ($Next_Action eq "print default screen") {
# don't drown  
# don't drown      ($Main_Body_Output) .= 
# don't drown  	$query->p("\n" . $query->start_form({-action=>"$this_pl"}) . 
# don't drown  		  "\n" . $query->textarea(-name=>'input_data',
# don't drown  					  -rows=>3,
# don't drown  					  -columns=>150) .
# don't drown  		  "\n" . $query->submit(-name=>'button', -value=>'submit data') .
# don't drown  		  "\n" . $query->reset(-name=>'clear',
# don't drown  				       -value=>'clear form') .
# don't drown  		  "\n" . $query->end_form
# don't drown  		  );
# don't drown      $Next_Action = "create button html";
# don't drown  }
# don't drown  
# don't drown  if ($Next_Action eq "create button html") {
# don't drown  # button code: meaning
# don't drown  #         who:  who have I had before and who will I have soon?
# don't drown  #         add:  add more data (display default screen)
# don't drown  #      add_id: add a new instructor to instructor DB
# don't drown  #      logout: erase login cookies
# don't drown  
# don't drown      my (@button_list);
# don't drown  
# don't drown      # add buttons wrapped in <td> tags for display in a table across the top row.
# don't drown      foreach my $button_code (split / /, $List_of_Buttons) {
# don't drown  	if ($button_code eq "who") { 
# don't drown  	    # create list of next 30 days
# don't drown  	    my @next_30_dates;
# don't drown  	    my %next_30_days;
# don't drown  	    my @days_of_week = qw(Sun Mon Tue Wed Thu Fri Sat);
# don't drown  	    foreach my $day_counter (-31..31) {
# don't drown  		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $day_counter*60*60*24 + $HOURS_FROM_CALI_TO_TOKYO*60*60);
# don't drown  		my $Todays_date = ($year + 1900) . "/" . ($mon + 1) . "/$mday";
# don't drown  		push (@next_30_dates, $Todays_date);
# don't drown  		$next_30_days{$Todays_date} = "$Todays_date $days_of_week[$wday]";
# don't drown  	    }
# don't drown  
# don't drown  	    push (@button_list,
# don't drown  		  td({-align=>"center"},
# don't drown  		     ["Who have I met?\n" . $query->br . $query->start_form({-action=>"$this_pl"}) . 
# don't drown  		      $query->submit(-name=>"button",-value=>"who") . $query->br .
# don't drown  		      $query->popup_menu(-name=>'date',
# don't drown  					 -values=>\@next_30_dates,
# don't drown  					 -labels=>\%next_30_days,
# don't drown  					 -default=>"$Todays_date" # this is the global var set at top of this page
# don't drown  					 ) .
# don't drown  		      $query->end_form]));
# don't drown  	    next; 
# don't drown  	}
# don't drown  	if ($button_code eq "add") { 
# don't drown  	    push (@button_list,
# don't drown  		  td({-align=>"center"},
# don't drown  		     ["Add more data\n" . $query->br . $query->start_form({-action=>"$this_pl"}) . $query->submit(-name=>"button",-value=>"add") . $query->end_form]));
# don't drown  	    next; 
# don't drown  	}
# don't drown  	if ($button_code eq "logout") { 
# don't drown  	    push (@button_list,
# don't drown  		  td({-align=>"center"},
# don't drown  		     ["Logout\n" . $query->br . $query->start_form({-action=>"$this_pl"}) . $query->submit(-name=>"button",-value=>"logout") . $query->end_form]));
# don't drown  	    next; 
# don't drown  	}
# don't drown  	if ($button_code eq "add_id") { 
# don't drown  	    push (@button_list,
# don't drown  		  td({-align=>"center"},
# don't drown  		     ["Add instructor\n" . $query->br . $query->start_form({-action=>"$this_pl"}) . $query->submit(-name=>"button",-value=>"add_ID") . $query->end_form]));
# don't drown  	    next; 
# don't drown  	}
# don't drown      }
# don't drown  
# don't drown      # smurf all the buttons together into one table row
# don't drown      ($Button_Output) .= $query->table({-border=>0},Tr(@button_list));
# don't drown  
# don't drown      # We have the main screen data and the navigation button data; display it and we're done.
# don't drown      $Next_Action = "get it together";
# don't drown  }
# don't drown  
# don't drown  if ($Next_Action eq "get it together") {
# don't drown      print $query->header, start_html("Rob's Gaba Student Tracker");
# don't drown      print $Button_Output;
# don't drown      print $detail_debug_msg if ($detail_debug_on);
# don't drown      print $Main_Body_Output;
# don't drown      print $query->end_html;
# don't drown  }
# don't drown  
# don't drown  sub processdata_add_reminder {
# don't drown      ($detail_debug_msg) .= $query->p("starting <b>processdata_add_reminder</b>:");
# don't drown      ($detail_debug_msg) .= $query->p("<br>parameters sent:");
# don't drown      foreach my $key ($query->param) {
# don't drown  	($detail_debug_msg) .= "<br>$key = " . $query->param("$key") . "\n";
# don't drown      }
# don't drown  
# don't drown      my $instructorID = $query->param("instructorID");
# don't drown      my $studentID = $query->param("studentID");
# don't drown      my $reminder = $query->param("reminder");
# don't drown  
# don't drown      my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	|| die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("adding <b>student_reminders</b> values (\"$instructorID\", \"$studentID\", \"$reminder\")");
# don't drown  
# don't drown      # insert each row that we created above
# don't drown      my $sql = "replace into student_reminders values (\"$instructorID\",
# don't drown                                                        \"$studentID\",
# don't drown                                                        \"$reminder\")";
# don't drown      my $sth = $dbh->prepare($sql);
# don't drown      $sth->execute;
# don't drown      $dbh->disconnect;
# don't drown      ($detail_debug_msg) .= $query->p("Finished <b>processdata_add_reminder</b>");
# don't drown  
# don't drown  }
# don't drown  
# don't drown  sub write_add_reminder_screen {
# don't drown  
# don't drown      my $studentID = $query->param("studentID");
# don't drown      my $instructorID = $query->param("instructorID");
# don't drown      my $count;  # will count the rows returned by query
# don't drown      my $reminder;  # will hold the reminder returned from query
# don't drown      my $student_name;
# don't drown      my $nashi;  # otherwise unused placeholder
# don't drown  
# don't drown      # look up the reminder
# don't drown      unless ($instructorID eq "" || $studentID eq "") {
# don't drown  	my $sql_name_query = qq{
# don't drown  	    SELECT name
# don't drown  		from student_names
# don't drown  		where studentID = "$studentID"
# don't drown  	    };
# don't drown  	my $sql_reminder_query = qq{
# don't drown  	    SELECT reminder
# don't drown  		from student_reminders
# don't drown  		where studentID = "$studentID"
# don't drown  		and instructorID = "$instructorID"
# don't drown  	    };
# don't drown  	
# don't drown  	my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	    || die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  	my $sth = $dbh->prepare($sql_name_query);
# don't drown  	$detail_debug_msg .= $query->pre($sql_name_query);
# don't drown  	$sth->execute();
# don't drown          $count =$sth->rows();
# don't drown  	($student_name) = $sth->fetchrow_array();
# don't drown  
# don't drown  	$sth = $dbh->prepare($sql_reminder_query);
# don't drown  	$detail_debug_msg .= $query->pre($sql_reminder_query);
# don't drown  	$sth->execute();
# don't drown          $count =$sth->rows();
# don't drown  	($reminder) = $sth->fetchrow_array();
# don't drown  	$dbh->disconnect();
# don't drown      } else {
# don't drown  	# error: studentID or instructorID not sent
# don't drown  	($Main_Body_Output) .= $query->p("Error: studentID or instructorID not sent");
# don't drown  	return;
# don't drown      }
# don't drown  
# don't drown      # Draw the form to edit the reminder
# don't drown      my $verb = ($count eq 1) ? "Edit the" : "Add a";
# don't drown      $Main_Body_Output .= "\n<p>$verb reminder for $student_name ($studentID)</p>\n";
# don't drown      # in the form below we have to specify the action or Perl will put all the URL-sent parameters on the action line
# don't drown      ($Main_Body_Output) .= $query->p($query->start_form({-action=>"$this_pl"}) . $query->hidden({-name=>"studentID"}) . 
# don't drown  				     $query->hidden({-name=>"instructorID"}) . $query->textfield(-name=>"reminder", -size=>100, -maxlength=>300, -value=>"$reminder") . 
# don't drown  				     $query->submit({-name=>"button", -value=>"add reminder to DB"}) . $query->end_form);
# don't drown  }
# don't drown  
# don't drown  sub write_add_instructor_screen {
# don't drown  
# don't drown      ($Main_Body_Output) .= $query->p("Add a new instructor to this system");
# don't drown  
# don't drown      ($Main_Body_Output) .= 
# don't drown  	$query->p("\n" . $query->start_form({-action=>"$this_pl"}) .
# don't drown  		  "\nInstructor's name: " . 
# don't drown  		  $query->textfield(-name=>'new_instructor_name',
# don't drown  				    -size=>40,
# don't drown  				    -maxlength=>40) .
# don't drown  		  "\n<br>Instructor's ID: " . 
# don't drown  		  $query->textfield(-name=>'new_instructorID',
# don't drown  				    -size=>10,
# don't drown  				    -maxlength=>10) .
# don't drown  		  "\n<br>Password: " . 
# don't drown  		  $query->password_field(-name=>'new_instructorPW',
# don't drown  					 -size=>20,
# don't drown  					 -maxlength=>20) .
# don't drown  		  "\n<br>Again: " . 
# don't drown  		  $query->password_field(-name=>'new_instructorPW2',
# don't drown  					 -size=>20,
# don't drown  					 -maxlength=>20) .
# don't drown  		  "\n<br>" . $query->submit(-name=>'button', -value=>'add instructor to DB') .
# don't drown  		  "\n<br>" . $query->reset(-name=>'clear',
# don't drown  					   -value=>'clear form') .
# don't drown  		  "\n" . $query->end_form
# don't drown  		  );
# don't drown  
# don't drown  };
# don't drown  
# don't drown  sub printreport_who {
# don't drown      ($detail_debug_msg) .= $query->p("Starting <b>printreport_who</b>:");
# don't drown  
# don't drown      my $sth;
# don't drown      my ($count_todays_students,$count_prev_students,$count_future_students,$count_again_students,$count_bad_rows);
# don't drown  
# don't drown      if($query->param("date")) {
# don't drown  	$Todays_date = $query->param("date");
# don't drown  	$detail_debug_msg .= "date = $Todays_date";
# don't drown      }
# don't drown  	
# don't drown      ($Main_Body_Output) .= $query->p($query->br("$instructor_name_logged_in"));
# don't drown  
# don't drown      # Select bad data and tell me abut it.
# don't drown      my $sql_look_for_bad_data = qq{
# don't drown  	SELECT * from lessons_taught where
# don't drown  	    date = "0000-00-00" 
# don't drown  	    OR time = "00:00:00" 
# don't drown  	};
# don't drown  
# don't drown      # Select the students who we have today and who we've had before
# don't drown      my $sql_had_before_query = qq{
# don't drown  	SELECT distinct L2.studentID, S.name, L2.instructorID, L2.date, L2.time, R.reminder
# don't drown  	    FROM lessons_taught L2, student_names S, lessons_taught L1
# don't drown  	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
# don't drown  						   AND L1.instructorID = R.instructorID)
# don't drown  	    WHERE (L1.studentID = L2.studentID
# don't drown  		   and L1.studentID = S.studentID
# don't drown  		   and L1.instructorID = "$userID_logged_in"
# don't drown  		   and L1.date < "$Todays_date")
# don't drown  	    and (L2.instructorID = "$userID_logged_in"
# don't drown  		 and L2.date = "$Todays_date")
# don't drown  	    and ((R.instructorID = "$userID_logged_in" and R.studentID = L1.studentID)
# don't drown  		 OR R.reminder IS NULL)
# don't drown  	    ORDER BY L2.date,L2.time
# don't drown  	};
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("Here is the query to select students had previously");
# don't drown      ($detail_debug_msg) .= $query->pre("$sql_had_before_query");
# don't drown  
# don't drown      my $sql_today_query = qq{
# don't drown  	SELECT L1.studentID, S.name, L1.instructorID, L1.date, L1.time, L1.choice, R.reminder
# don't drown  	    FROM lessons_taught L1, student_names S
# don't drown  	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
# don't drown  						   AND L1.instructorID = R.instructorID)
# don't drown  	    WHERE L1.studentID = S.studentID
# don't drown  	    and L1.date = "$Todays_date"
# don't drown  	    and L1.instructorID = "$userID_logged_in"
# don't drown  	    and ((R.instructorID = "$userID_logged_in" and R.studentID = L1.studentID)
# don't drown  		 OR R.reminder IS NULL)
# don't drown  	    ORDER BY date,time
# don't drown   	};
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("Here is the query to select students from today");
# don't drown      ($detail_debug_msg) .= $query->pre("$sql_today_query");
# don't drown  
# don't drown      my $sql_future_query = qq{
# don't drown  	SELECT L1.studentID, S.name, L1.instructorID, L1.date, L1.time
# don't drown  	    FROM lessons_taught L1, student_names S
# don't drown  	    WHERE L1.studentID = S.studentID
# don't drown  	    and L1.date > "$Todays_date"
# don't drown  	    and L1.instructorID = "$userID_logged_in"
# don't drown  	};
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("Here is the query to select students we'll have later");
# don't drown      ($detail_debug_msg) .= $query->pre("$sql_future_query");
# don't drown  
# don't drown      # Select the students who we have today and we'll have again
# don't drown      my $sql_have_again_query = qq{
# don't drown  	SELECT distinct L2.studentID, S.name, L2.instructorID, L1.date, L1.time, R.reminder
# don't drown  	    FROM lessons_taught L2, student_names S, lessons_taught L1
# don't drown  	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
# don't drown  						   AND L1.instructorID = R.instructorID)
# don't drown  	    WHERE (L1.studentID = L2.studentID
# don't drown  		   and L1.studentID = S.studentID
# don't drown  		   and L1.instructorID = "$userID_logged_in"
# don't drown  		   and L1.date > "$Todays_date")
# don't drown  	    and (L2.instructorID = "$userID_logged_in"
# don't drown  		 and L2.date = "$Todays_date")
# don't drown  	    and ((R.instructorID = "$userID_logged_in" and R.studentID = L1.studentID)
# don't drown  		 OR R.reminder IS NULL)
# don't drown  	    ORDER BY date,time
# don't drown  	};
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("Here is the query to select students we'll have again");
# don't drown      ($detail_debug_msg) .= $query->pre("$sql_have_again_query");
# don't drown  
# don't drown  # $$$ HERE
# don't drown      my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	|| die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown      $sth = $dbh->prepare ( $sql_look_for_bad_data );
# don't drown      $sth->execute;
# don't drown      $count_bad_rows = $sth->rows();
# don't drown      my $naughty_naughty_zoot = $sth->fetchall_arrayref();
# don't drown  
# don't drown      $sth = $dbh->prepare ( $sql_had_before_query );
# don't drown      $sth->execute;
# don't drown      $count_prev_students = $sth->rows();
# don't drown      my $had_before_results = $sth->fetchall_arrayref();
# don't drown  
# don't drown      $sth = $dbh->prepare ( $sql_today_query );
# don't drown      $sth->execute;
# don't drown      $count_todays_students = $sth->rows();
# don't drown      my $today_results = $sth->fetchall_arrayref();
# don't drown  
# don't drown      $sth = $dbh->prepare ( $sql_future_query );
# don't drown      $sth->execute;
# don't drown      $count_future_students = $sth->rows();
# don't drown      my $future_results = $sth->fetchall_arrayref();
# don't drown  
# don't drown      $sth = $dbh->prepare ( $sql_have_again_query );
# don't drown      $sth->execute;
# don't drown      $count_again_students = $sth->rows();
# don't drown      my $again_results = $sth->fetchall_arrayref();
# don't drown  
# don't drown      $sth->finish();
# don't drown      $dbh->disconnect();
# don't drown      
# don't drown      # Now create the report
# don't drown      my ($n,$record,$studentID,$student_name,$instructorID,$date,$time,$choice,$reminder);
# don't drown  
# don't drown      if ($count_bad_rows) {
# don't drown  	($Main_Body_Output) .= $query->p("We just got some bad data!");
# don't drown  	foreach $record (@$naughty_naughty_zoot) {
# don't drown  	    my $crud;
# don't drown  	    foreach my $crizap (@$record) {
# don't drown  		$crud .= "~" . mkdef ($crizap);
# don't drown  	    }
# don't drown  	    ($Main_Body_Output) .= $query->br($crud);
# don't drown  	}  # end show bad rows
# don't drown      }  # if bad rows
# don't drown  
# don't drown      # display students we have today
# don't drown      ($Main_Body_Output) .= $query->p("These are the $count_todays_students students you have today. (* = chosen)");
# don't drown      foreach $record (@$today_results) {
# don't drown  	# Parse each record array and display 
# don't drown  
# don't drown  	($studentID, $student_name, $instructorID, $date, $time, $choice, $reminder) = @$record;
# don't drown  	($Main_Body_Output) .= $query->br . "$date $time " .
# don't drown  	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabaMain/lc/studentprofile_lessonrecord.asp?txtStudentID=$studentID",
# don't drown  		       -target=>"_blank"}, "$studentID $student_name");
# don't drown  	($Main_Body_Output) .= " *" if ($choice eq "true");
# don't drown  	($Main_Body_Output) .= " " . $query->a({-href=>"$this_pl?studentID=$studentID&instructorID=$userID_logged_in&button=add_reminder&date=$date"}, "edit");
# don't drown  	($Main_Body_Output) .= " " . mkdef($reminder);
# don't drown      }
# don't drown  
# don't drown      # display students we have had before 
# don't drown      ($Main_Body_Output) .= $query->p("These are the $count_prev_students students you've had before.");
# don't drown      foreach $record (@$had_before_results) {
# don't drown  	# Parse each record array and display 
# don't drown  	($studentID, $student_name, $instructorID, $date, $time, $reminder) = @$record;
# don't drown  	($Main_Body_Output) .= $query->br . "$date $time " .
# don't drown  	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabamain/LC/alllessonrecords.asp?txtStudentID=$studentID",
# don't drown  		       -target=>"_blank"}, "$studentID $student_name");
# don't drown  	($Main_Body_Output) .= " " . $query->a({-href=>"$this_pl?studentID=$studentID&instructorID=$userID_logged_in&button=add_reminder"}, "edit");
# don't drown  	($Main_Body_Output) .= " " . mkdef($reminder);
# don't drown      }
# don't drown  
# don't drown      ($Main_Body_Output) .= $query->p("You are scheduled to have <b>$count_future_students students</b> after today.");
# don't drown  
# don't drown      # display today's students that we'll have again
# don't drown      ($Main_Body_Output) .= $query->p("Of today's students, you will have these soon.");
# don't drown      foreach $record (@$again_results) {
# don't drown  	# Parse each record array and display 
# don't drown  	($studentID, $student_name, $instructorID, $date, $time, $reminder) = @$record;
# don't drown  	($Main_Body_Output) .= $query->br . "$date $time " .
# don't drown  	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabamain/LC/alllessonrecords.asp?txtStudentID=$studentID",
# don't drown  		       -target=>"_blank"}, "$studentID $student_name");
# don't drown  	($Main_Body_Output) .= " " . $query->a({-href=>"$this_pl?studentID=$studentID&instructorID=$userID_logged_in&button=add_reminder"}, "edit");
# don't drown  	($Main_Body_Output) .= " " . mkdef($reminder);
# don't drown      }
# don't drown  
# don't drown  
# don't drown  }
# don't drown  
# don't drown  sub processdata_add_instructor {
# don't drown  
# don't drown      # check to see if the passwords match
# don't drown      if ($query->param("new_instructorPW") ne $query->param("new_instructorPW2")) {
# don't drown  	($Main_Body_Output) .= $query->p($query->b("passwords do not match.  Try again."));
# don't drown      } else {
# don't drown  	($Main_Body_Output) .= $query->br("Adding " . $query->param("new_instructor_name"));
# don't drown  
# don't drown  	$Main_Body_Output .= "<br>Please wait.\n";
# don't drown  
# don't drown  	my $new_instructorID = $query->param("new_instructorID");
# don't drown  	my $new_instructorPW = $query->param("new_instructorPW");
# don't drown  	my $new_instructor_name = $query->param("new_instructor_name");
# don't drown  
# don't drown  	my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	    || die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown  	# insert each row that we created above
# don't drown          my $sql = "insert into instructor_names values ('$new_instructorID',
# don't drown                                                          '$new_instructorPW',
# don't drown                                                          '$new_instructor_name', '')";
# don't drown  	my $sth = $dbh->prepare($sql);
# don't drown  	$sth->execute;
# don't drown  	$dbh->disconnect;
# don't drown  	$Main_Body_Output .= "<br>Finished.\n";
# don't drown  
# don't drown      }
# don't drown  }
# don't drown  
# don't drown  sub processdata_add_choices {
# don't drown      my @input_buffer = split /\n+/, $query->param("input_data");
# don't drown      my $input_buffer_instructorID;
# don't drown      my @lessons_taught_output_rows;
# don't drown      my @student_names_output_rows;
# don't drown      my $record_counter = 0;
# don't drown      my $nashi; # used as placeholder for unneeded data
# don't drown      my (@times, @tds);
# don't drown      my ($reportStartDate,$rptSYear,$rptSMonth,$rptSDate); # date range of the html report data entered
# don't drown  
# don't drown      # Read from instructor_names what instructorIDs we care to process
# don't drown      my $sql_instructorID_query = 
# don't drown  	qq(SELECT instructorID from instructor_names;);
# don't drown  				    
# don't drown      my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	|| die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown      my $sth = $dbh->prepare ( $sql_instructorID_query );
# don't drown      $sth->execute;
# don't drown      my $instructorID_results = $sth->fetchall_arrayref();
# don't drown      $sth->finish();
# don't drown      $dbh->disconnect();
# don't drown      
# don't drown      my ($instructorIDs_bar_separator,$instructorIDs_comma_separator,@instructorIDs);
# don't drown  
# don't drown      # display students we have today
# don't drown      foreach my $record (@$instructorID_results) {
# don't drown  	push (@instructorIDs, @$record);
# don't drown      }
# don't drown  
# don't drown      $instructorIDs_bar_separator = join ("|", @instructorIDs);     # this is used in regex below
# don't drown      $instructorIDs_comma_separator = join (", ", @instructorIDs);  # this is used in mySql code below
# don't drown      $detail_debug_msg .= "<br>We will look for these instructor IDs: $instructorIDs_comma_separator";
# don't drown  	
# don't drown      my $attr_ref;  # will point to attributes inside tag
# don't drown      my $tag_ref; # will point to tag and attributes
# don't drown  
# don't drown      my $START_TOKEN_PREFIX = "Token>";
# don't drown      my $START_TEXT_PREFIX = "Text>";
# don't drown      my $p = HTML::PullParser->new 
# don't drown  	( doc => $query->param("input_data"),
# don't drown  	  report_tags => [qw(td span)],                    # only care about these tags
# don't drown  	  start => "'$START_TOKEN_PREFIX', tagname, attr", # tell me the tagname and attributes when you see one
# don't drown  	  text => "'$START_TEXT_PREFIX', text"             # tell me the text between tags
# don't drown  	);
# don't drown  
# don't drown      # look for date and then look for times at the top of the table
# don't drown      while ($tag_ref = $p->get_token) {
# don't drown  	unless ($reportStartDate) {
# don't drown  	    if ($$tag_ref[0] eq $START_TEXT_PREFIX && mkdef($$tag_ref[1]) =~ /DATE:/) {
# don't drown  		$tag_ref = $p->get_token;
# don't drown  		$reportStartDate = $$tag_ref[1];
# don't drown  		$Main_Body_Output .= "\n<p>Added student choices for $reportStartDate</p>\n";
# don't drown  		($rptSMonth,$rptSDate,$rptSYear) = split ("/", $reportStartDate);
# don't drown  	    }
# don't drown  	}
# don't drown  	if ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "td") {
# don't drown  	    $attr_ref = mkdef($$tag_ref[2]);
# don't drown  	    
# don't drown  	    # td tags with this class are the times at the top of the report
# don't drown  	    if (mkdef($$attr_ref{"class"}) eq "gabaBoxTitle") {
# don't drown  		my $time_ref= $p->get_token;
# don't drown  		push @times, $$time_ref[1];
# don't drown  	    }
# don't drown  	} elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "span") {
# don't drown  	    $p->unget_token($tag_ref);	    # put the span token back on so we can take it off in the next while loop
# don't drown  	    last;	                    # jump out of looking for times loop
# don't drown  	}
# don't drown      } # end look for date and times
# don't drown  
# don't drown      $detail_debug_msg .= "\n<p>These are the lesson times:\n<br>" . join (" - ", @times) . "</p>\n";
# don't drown  
# don't drown      while ($tag_ref = $p->get_token) {
# don't drown  	# instructorIDs are inside span tags
# don't drown  	if ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "span") {
# don't drown  	    $attr_ref = mkdef($$tag_ref[2]);
# don't drown  
# don't drown  	    # if the span tag has a title including an instructor we care about, then process it
# don't drown  	    if (mkdef($$attr_ref{"title"}) =~ /$instructorIDs_bar_separator/) {
# don't drown  
# don't drown  		$detail_debug_msg .= $query->br . "FOUND YOU" . join (":", %$attr_ref);
# don't drown  		my ($instructorID) = mkdef($$attr_ref{"title"}) =~ /\w*:\s(\d*)/;
# don't drown  
# don't drown  		# count TDs
# don't drown  		my $count_TDs = -1;
# don't drown  		while ($tag_ref = $p->get_token) {
# don't drown  
# don't drown  		    # if we're looking at a new instructor ID, then break out of this while loop
# don't drown  		    if ($$tag_ref[0] eq $START_TOKEN_PREFIX 
# don't drown  			&& mkdef($$tag_ref[1]) eq "span"
# don't drown  			&& mkdef($$tag_ref[2]{"title"}) =~ /InstructorID/
# don't drown  			) {
# don't drown  			$p->unget_token($tag_ref);	    # put the span token back on so we can take it off in the next while loop
# don't drown  			last;	                    # jump out of looking for times loop
# don't drown  		    } elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX 
# don't drown  			&& mkdef($$tag_ref[1]) eq "span") {
# don't drown  			$attr_ref = mkdef($$tag_ref[2]);
# don't drown  			my ($studentID) = mkdef($$attr_ref{"title"}) =~ /(\d*)/;
# don't drown  			my $choice = (mkdef($$attr_ref{"style"}) =~ /blue/) ? "true" : "false";
# don't drown  
# don't drown  			if ($studentID) {
# don't drown  			    my $time = mkdef($times[$count_TDs]);
# don't drown  			    push (@lessons_taught_output_rows,
# don't drown  				  "insert into lessons_taught values ('$studentID','$instructorID','$rptSYear/$rptSMonth/$rptSDate','$time:00','$choice');");
# don't drown  			}
# don't drown  		    } elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX 
# don't drown  			     && mkdef($$tag_ref[1]) eq "td") {
# don't drown  			$count_TDs++;
# don't drown  		    } # end tag is a TD
# don't drown  		} # end while counting TDs
# don't drown  	    } # end this is an instructor we care about
# don't drown  	} # end we are now looking at instructor schedules
# don't drown      } # end processing HTML input
# don't drown  
# don't drown      # Next we will wipe pre-existing data for this instructor and date range and then add new records to db.
# don't drown      my $delete_sql = "DELETE FROM lessons_taught WHERE date = \"$rptSYear/$rptSMonth/$rptSDate\" and instructorID IN ($instructorIDs_comma_separator);";
# don't drown  
# don't drown      $detail_debug_msg .= $query->pre("$delete_sql");
# don't drown  
# don't drown      $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	|| die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown      $sth = $dbh->prepare($delete_sql);
# don't drown      $sth->execute;
# don't drown  
# don't drown      # process each row that we created above
# don't drown      foreach my $sql (@lessons_taught_output_rows) {
# don't drown  	($detail_debug_msg) .= $query->pre("$sql");
# don't drown  	my $sth = $dbh->prepare($sql);
# don't drown  	$sth->execute;
# don't drown      }
# don't drown  
# don't drown      $sth->finish();
# don't drown      $dbh->disconnect;
# don't drown  
# don't drown  #    $Main_Body_Output .= "<br>$record_counter records inputted for dates $reportStartDate - $reportEndDate\n";
# don't drown  
# don't drown      $detail_debug_msg .= "<br>end processing data for choices\n";
# don't drown  
# don't drown  }
# don't drown  
# don't drown  sub processdata_who {
# don't drown      my @input_buffer = split /\n+/, $query->param("input_data");
# don't drown      my $input_buffer_instructorID;
# don't drown      my @lessons_taught_output_rows;
# don't drown      my @student_names_output_rows;
# don't drown      my $record_counter = 0;
# don't drown      my $nashi; # used as placeholder for unneeded data
# don't drown      my ($reportStartDate,$rptSYear,$rptSMonth,$rptSDate,$reportEndDate,$rptEYear,$rptEMonth,$rptEDate); # date range of the html report data entered
# don't drown  
# don't drown  ####  THESE CAN BE LOCAL TO THE LOOP BELOW, but it doesn't really matter, I guess.
# don't drown      my ($month,$date,$year,$hour,$minute,$meridian,$studentID,$student_name,$instructorID);
# don't drown  
# don't drown      $detail_debug_msg .= "<br>processing data for who\n";
# don't drown      $detail_debug_msg .= "\n<pre>\n";
# don't drown      foreach (@input_buffer) {
# don't drown  	# figure out for what dates this report is being run
# don't drown  	if (/Student Lessons Scheduled for/) {
# don't drown  	    ($reportStartDate,$rptSMonth,$rptSDate,$rptSYear,$nashi,$reportEndDate,$rptEMonth,$rptEDate,$rptEYear) = 
# don't drown  		$_ =~ m|Student Lessons Scheduled for.\s+((\d+)/(\d+)/(\d+))(\s+-\s+((\d+)/(\d+)/(\d+)))*|;
# don't drown  	    ($rptEMonth,$rptEDate,$rptEYear,$reportEndDate) = ($rptSMonth,$rptSDate,$rptSYear,$reportStartDate) unless (defined $reportEndDate);
# don't drown  	}
# don't drown  
# don't drown  	# figure out for what instructor this report is written
# don't drown  	if (/\[(\d+)\]/) {
# don't drown  	    $input_buffer_instructorID = $1;
# don't drown  	}
# don't drown  
# don't drown  	if (/\d+\/\d+\/\d+\s+\d+:\d+.M/) {  # lines containing this text should be processed
# don't drown  	    $record_counter ++;
# don't drown  	    ($month,$date,$year,$hour,$minute,$meridian,$studentID,$student_name,$instructorID) = 
# don't drown  		$_ =~ m|(\d+)/(\d+)/(\d+)\s+(\d+):(\d+)(.M)\s+(\d+)\s+(\w+\s+\w+)\s+(\d+)|;
# don't drown  
# don't drown  	    $date = substr("0$date",-2,2);      # force date to be 0 padded
# don't drown  	    $month = substr("0$month",-2,2);    # force month to be 0 padded
# don't drown  	    $studentID =substr("              $studentID",-$STUDENT_ID_LEN,$STUDENT_ID_LEN);  # force student ID to be padded with spaces
# don't drown  	    if ($meridian eq "PM" and $hour ne "12") {
# don't drown  		$hour += 12;                    # use military time
# don't drown  	    }
# don't drown  
# don't drown  	    # put the data here so we can sql it in one loop outside this regex block
# don't drown  	    push (@lessons_taught_output_rows,"insert into lessons_taught values ('$studentID','$instructorID','$year/$month/$date','$hour:$minute:00','false');");
# don't drown  	    push (@student_names_output_rows,"insert ignore into student_names values ('$studentID','$student_name');");
# don't drown  
# don't drown  #	    $detail_debug_msg .=  "$month/$date/$year $hour:$minute $studentID $student_name $instructorID\n";
# don't drown  	}
# don't drown      }
# don't drown      $detail_debug_msg .= "</pre>\n";
# don't drown  
# don't drown      # Now we have grabbed all the data we need from the input HTML.  
# don't drown      # Below, we remove records from the date range we're about to insert.
# don't drown      # That's because we are "mirroring" Gaba's DB; they might have removed a lesson since the last time we inserted
# don't drown  
# don't drown  # $$$ HERE
# don't drown  
# don't drown      my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# don't drown  	|| die "Oops.  Could not connect to database: " . DBI->errstr;
# don't drown  
# don't drown      # Next we will wipe pre-existing data for this instructor and date range and then add new records to db.
# don't drown      my $sql = "DELETE FROM lessons_taught WHERE date BETWEEN \"$rptSYear/$rptSMonth/$rptSDate\" and \"$rptEYear/$rptEMonth/$rptEDate\" and instructorID = $input_buffer_instructorID;";
# don't drown  
# don't drown      ($detail_debug_msg) .= $query->p("Deleting records for instructor $input_buffer_instructorID for dates $reportStartDate - $reportEndDate");
# don't drown      ($detail_debug_msg) .= $query->pre("$sql");
# don't drown  
# don't drown      my $sth = $dbh->prepare($sql);
# don't drown      $sth->execute;
# don't drown  
# don't drown      # process each row that we created above
# don't drown      foreach my $sql (@lessons_taught_output_rows) {
# don't drown  	($detail_debug_msg) .= $query->pre("$sql");
# don't drown  	my $sth = $dbh->prepare($sql);
# don't drown  	$sth->execute;
# don't drown      }
# don't drown  
# don't drown      # process each row that we created above
# don't drown      foreach my $sql (@student_names_output_rows) {
# don't drown  	($detail_debug_msg) .= $query->pre("$sql");
# don't drown  	my $sth = $dbh->prepare($sql);
# don't drown  	$sth->execute;
# don't drown      }
# don't drown  
# don't drown      $dbh->disconnect;
# don't drown  
# don't drown      $Main_Body_Output .= "<br>$record_counter records inputted for dates $reportStartDate - $reportEndDate\n";
# don't drown  
# don't drown      $detail_debug_msg .= "<br>end processing data for who\n";
# don't drown  }
# don't drown  

sub look_for_input_data {

    $detail_debug_msg .= "\n<p>Input data:";

    # for debugging params
    my @params = $query->param;
    foreach my $param (@params) { $detail_debug_msg .= "<br>" . $param . "=" . $query->param("$param"); }
    $detail_debug_msg .= "</p>\n";

    # allowable Next_Actions:
    # (allow others by adding to elsif in main code above)
    $Next_Action = "printreport xx";
    $Next_Action = "processdata xx";
    # $Next_Action = "print default screen";   # this one has been handled

    # $mode might be better as a global var
    my $mode = mkdef($query->param("m"));

    if ($mode eq "topscores") {
	$Next_Action = "display topscores";
    } elsif ($mode eq "calculate") {
	$Next_Action = "process raw string";
    } else {
	# The user wants to view the screen to try an entry; this is the default
	$mode = "try";
	$Next_Action = "display default screen";
    }



# don't drown     if (mkdef($query->param("button")) eq "who") {
# don't drown 	$Next_Action = "printreport who";
# don't drown     } elsif (mkdef($query->param("button")) eq "submit data") {
# don't drown 	# look at param input_data to see what data was inputted
# don't drown 	my $inputted_html = mkdef($query->param("input_data"));
# don't drown 	if ($inputted_html =~ m/Client Lesson Instructor Schedule/i) {
# don't drown 	    $Next_Action = "processdata who";
# don't drown 	} elsif ($inputted_html =~ m|<title>Learning Studio Lessons View</title>|i) {
# don't drown 	    $Next_Action = "add choices to db";
# don't drown 	} else {
# don't drown 	    $Next_Action = "complain about invalid data";
# don't drown 	}
# don't drown     } elsif (mkdef($query->param("button")) eq "add_ID") {
# don't drown 	$Next_Action = "draw add instructor screen";
# don't drown     } elsif (mkdef($query->param("button")) eq "add_reminder") {
# don't drown 	$Next_Action = "draw add reminder screen";
# don't drown     } elsif (mkdef($query->param("button")) eq "add instructor to DB") {
# don't drown 	$Next_Action = "add instructor to db";
# don't drown     } elsif (mkdef($query->param("button")) eq "add reminder to DB") {
# don't drown 	$Next_Action = "add reminder to db";
# don't drown     } else {
# don't drown 	$detail_debug_msg .= "<br>no input data found";
# don't drown 	$Next_Action = "print default screen";
# don't drown     }

#    $detail_debug_msg = "";  #  if this code starts to fuck up, remove this line

##  just set $Next_Action and be done with it.    # return $Next_Action to explain what to do next
##    $Next_Action;
}


sub check_authentication {
#  We are going to have to make new DBs (design them first) and retool this code.
#  We are going to have to make new DBs (design them first) and retool this code.
#  We are going to have to make new DBs (design them first) and retool this code.
#  We are going to have to make new DBs (design them first) and retool this code.
#  We are going to have to make new DBs (design them first) and retool this code.

# start here, later.     my (%cookies_read, $instructorID,$instructorPW,$Next_Action);
# start here, later.     my ($sth,$dbh);
# start here, later. 
# start here, later.     %cookies_read = fetch CGI::Cookie;
# start here, later. 
# start here, later.     $detail_debug_msg .= "\n<p>Found these cookies:";
# start here, later.     foreach (keys %cookies_read) {
# start here, later. 	$detail_debug_msg .= "<br>$cookies_read{$_}";
# start here, later.     }
# start here, later. 
# start here, later.     # look for login-cookies.  Entered params supercede them.  "Logout" supercedes all.
# start here, later.     # big if: (even if they are logged in,) hitting logout supercedes any cookies
# start here, later.     if (mkdef($query->param("button")) eq "logout") {
# start here, later. 	$instructorID = "delete";  $instructorPW = "delete";   # when set_cookies is run, these will be deleted
# start here, later.     } else {
# start here, later. 	if (mkdef($query->param("instructorID"))) {
# start here, later. 	    $instructorID = mkdef($query->param("instructorID"));
# start here, later. 	} elsif ($cookies_read{'instructorID'}) {
# start here, later. 	    $instructorID=$cookies_read{'instructorID'} -> value;
# start here, later. 	} else {
# start here, later. 	    $instructorID = "";
# start here, later. 	}
# start here, later. 
# start here, later. 	if (mkdef($query->param("instructorPW"))) {
# start here, later. 	    $instructorPW = mkdef($query->param("instructorPW"));
# start here, later. 	} elsif ($cookies_read{'instructorPW'}) {
# start here, later. 	    $instructorPW=$cookies_read{'instructorPW'} -> value;
# start here, later. 	} else {
# start here, later. 	    $instructorPW = "";
# start here, later. 	}
# start here, later.     }
# start here, later. 
# start here, later.     # assume we don't have valid credentials
# start here, later.     $Next_Action = "draw login screen";
# start here, later. 
# start here, later.     # This [unless] isn't needed to keep out anonymous visitors, but is added to make the code a bit faster
# start here, later.     unless ($instructorID eq "" || $instructorPW eq "") {
# start here, later. 	my $sql_query = qq{ 
# start here, later. 	    SELECT *
# start here, later. 		FROM instructor_names
# start here, later. 		WHERE instructorID = "$instructorID"
# start here, later. 		and password = "$instructorPW" };
# start here, later. 	
# start here, later. 	$dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
# start here, later. 	    || die "Oops.  Could not connect to database: " . DBI->errstr;
# start here, later. 	$sth = $dbh->prepare($sql_query);
# start here, later. 	$sth->execute;
# start here, later. 	my $count_rows = $sth->rows();
# start here, later. 	my $nashi;  # otherwise unused placeholder
# start here, later. 	my $button_codes; # give special powers to certain users
# start here, later. 	($userID_logged_in,$button_codes) = $sth->fetchrow_array();
# start here, later. 	$sth->finish();
# start here, later. 	$dbh->disconnect();
# start here, later. 
# start here, later. 	# a row with supplied credentials was found, so allow login to proceed
# start here, later. 	if ($count_rows) {
# start here, later. 	    $List_of_Buttons .= " $button_codes ";
# start here, later. 	    $Next_Action = "look for input data";
# start here, later. 	} else {
# start here, later. 	    # the credentials sent didn't match anything, so delete the cookies
# start here, later. 	    $instructorID = "delete";   # when set_cookies is run, $instructorID will be deleted
# start here, later. 	    $instructorPW = "delete";   # when set_cookies is run, $instructorPW will be deleted
# start here, later. 	    $Next_Action = "draw login screen";  # this is redundant but helps legibility
# start here, later. 	}
# start here, later. 
# start here, later. 	$cookie{'instructorID'} = $instructorID;
# start here, later. 	$cookie{'instructorPW'} = $instructorPW;
# start here, later. 	$detail_debug_msg .= "\n<p>We just " . &setCookies(%cookie);
# start here, later.     }
# start here, later. 
# start here, later. #    $detail_debug_msg = "";  #  if this code starts to fuck up, remove this line
# start here, later. 
# start here, later.     # return what we should do next ($Next_Action)
# start here, later.     $Next_Action;

    $Next_Action = "look for input";
}

sub mkdef {
    my($ival) = @_;

    if (defined $ival) {
	return $ival;
    } else {
	return "";
    }
}
