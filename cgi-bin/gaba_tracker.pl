#!/usr/bin/perl -w

# In my final days of working at Gaba, they seem to have blocked
# access to robnugen.com.  I can use silentsurf.com to get to my gaba
# tracker, but it doesn't handle cookies properly (I believe).  So
# this version doesn't use cookies, but does use hidden fields to pass
# the user/pass parameters.

use strict;
use CGI qw(:all fatalsToBrowser);
use CGI::Cookie;
use DBI;
use HTML::PullParser;
require "setCookies.pl";  # a proven method to write cookies; I'm not sure how to do it with straight CGI objects.

my $gaba_tracker_pl =  $ENV{'SCRIPT_NAME'};
my $debug_on = 0;
my $HOURS_FROM_CALI_TO_TOKYO = 16;  # add N hours worth of seconds to get from California time to Japan time.  This will have to change at Daylight Saving shifts

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $HOURS_FROM_CALI_TO_TOKYO*60*60);
my $Todays_date = ($year + 1900) . "/" . ($mon + 1) . "/$mday";

my $query = new CGI;
my %cookie; # this is a hash of cookies with which we'll store instructorID and instructorPW

my $STUDENT_ID_LEN = 6;

my $serverHostname = "db1.webquarry.com";
my $serverUsername = "rob";
my $serverPassword = "ba30gaIM";
my $serverDatabase = "rob";

my $Main_Body_Output = "";    # this will store the html source of the main part of the window
my $Button_Output = "";       # this will store the html source of the navigation
my $Next_Action = "";         # will keep track of what we're supposed to do
my $debug_msg = "";           # for debugging
my $debug_msg = "$gaba_tracker_pl";           # for debugging

my $instructorID_logged_in = "";
my $instructor_name_logged_in = "";

# these should be read from each users list, eventually.  		
# That will allow them to put their buttons in their own specific order
# button defs near "create button html"
my $_temp_for_now_List_of_Buttons = "who logout add";

# First thing we do is check the credentials of whoever is using the system
$Next_Action = &check_authentication;  # possible results are "draw login screen" and "look for input data"

if ($Next_Action eq "draw login screen") {
    print $query->header, $query->start_html("Gaba tracker login");
    print "$debug_msg" if ($debug_on);  # this will be any debug info written by the previously run code (&check_authentication)
    print $query->h3("login");
    print $query->p( $query->start_form, 
		     "\n", $query->br,
		     $query->textfield(-name=>'instructorID',-size=>12),
		     "\n", $query->br,
		     $query->password_field(-name=>'instructorPW',-size=>12),
		     $query->submit(-name=>'login'),
		     $query->end_form
		     );
    print $query->end_html;

    $Next_Action = "finished";  # do nothing else this run
} else {
    $Next_Action = &look_for_input_data;
}

# This one might benefit from handling printreport ___, using the second token as a parameter
if ($Next_Action eq "processdata who") {
    &processdata_who;
    $Next_Action = "printreport who";
} elsif ($Next_Action eq "add instructor to db") {
    &processdata_add_instructor;
    $Next_Action = "create button html";
} elsif ($Next_Action eq "add choices to db") {
    &processdata_add_choices;
    $Next_Action = "printreport who";
} elsif ($Next_Action eq "add reminder to db") {
    &processdata_add_reminder;
    $Next_Action = "printreport who";
}


if ($Next_Action eq "printreport who") {
    &printreport_who;
    $Next_Action = "create button html";
} elsif ($Next_Action eq "draw add instructor screen") {
    &write_add_instructor_screen;
    $Next_Action = "create button html";
} elsif ($Next_Action eq "draw add reminder screen") {
    &write_add_reminder_screen;
    $Next_Action = "create button html";
} elsif ($Next_Action eq "complain about invalid data") {
    $Main_Body_Output .= "<br>I don't know how to process the data you entered";
    $Next_Action = "print default screen";
}

if ($Next_Action eq "print default screen") {

    ($Main_Body_Output) .= 
	$query->p("\n" . $query->start_form({-action=>"$gaba_tracker_pl"}) . 
		  "\n" . $query->textarea(-name=>'input_data',
					  -rows=>3,
					  -columns=>150) .
		  "\n" . $query->submit(-name=>'button', -value=>'submit data') .
		  "\n" . $query->reset(-name=>'clear',
				       -value=>'clear form') .
		  "\n" . $query->hidden(-name=>'instructorID',-size=>12) .
		  "\n" . $query->hidden(-name=>'instructorPW',-size=>12) .
		  "\n" . $query->end_form
		  );
    $Next_Action = "create button html";
}

if ($Next_Action eq "create button html") {
# button code: meaning
#         who:  who have I had before and who will I have soon?
#         add:  add more data (display default screen)
#      add_id: add a new instructor to instructor DB
#      logout: erase login cookies

    my (@button_list);

    # add buttons wrapped in <td> tags for display in a table across the top row.
    foreach my $button_code (split / /, $_temp_for_now_List_of_Buttons) {
	if ($button_code eq "who") { 
	    # create list of next 30 days
	    my @next_30_dates;
	    my %next_30_days;
	    my @days_of_week = qw(Sun Mon Tue Wed Thu Fri Sat);
	    foreach my $day_counter (-31..31) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $day_counter*60*60*24 + $HOURS_FROM_CALI_TO_TOKYO*60*60);
		my $Todays_date = ($year + 1900) . "/" . ($mon + 1) . "/$mday";
		push (@next_30_dates, $Todays_date);
		$next_30_days{$Todays_date} = "$Todays_date $days_of_week[$wday]";
	    }

	    push (@button_list,
		  td({-align=>"center"},
		     ["Who have I met?\n" . $query->br . $query->start_form({-action=>"$gaba_tracker_pl"}) . 
		      $query->submit(-name=>"button",-value=>"who") . $query->br .
		      $query->popup_menu(-name=>'date',
					 -values=>\@next_30_dates,
					 -labels=>\%next_30_days,
					 -default=>"$Todays_date" # this is the global var set at top of this page
					 ) .
		     $query->hidden(-name=>'instructorID',-size=>12) .
		     $query->hidden(-name=>'instructorPW',-size=>12) .

		      $query->end_form]));
	    next; 
	}
	if ($button_code eq "add") { 
	    push (@button_list,
		  td({-align=>"center"},
		     ["Add more data\n" . $query->br . 
		      $query->start_form({-action=>"$gaba_tracker_pl"}) . 
		      $query->submit(-name=>"button",-value=>"add") . 
		      $query->hidden(-name=>'instructorID',-size=>12) .
		      $query->hidden(-name=>'instructorPW',-size=>12) .
		      $query->end_form]));
	    next; 
	}
	if ($button_code eq "logout") { 
	    push (@button_list,
		  td({-align=>"center"},
		     ["Logout\n" . $query->br . 
		      $query->start_form({-action=>"$gaba_tracker_pl"}) . 
		      $query->submit(-name=>"button",-value=>"logout") . 
		      $query->hidden(-name=>'instructorID',-size=>12) .
		      $query->hidden(-name=>'instructorPW',-size=>12) .
		      $query->end_form]));
	    next; 
	}
	if ($button_code eq "add_id") { 
	    push (@button_list,
		  td({-align=>"center"},
		     ["Add instructor\n" . $query->br . 
		      $query->start_form({-action=>"$gaba_tracker_pl"}) . 
		      $query->submit(-name=>"button",-value=>"add_ID") . 
		      $query->hidden(-name=>'instructorID',-size=>12) .
		      $query->hidden(-name=>'instructorPW',-size=>12) .
		      $query->end_form]));
	    next; 
	}
    }

    # smurf all the buttons together into one table row
    ($Button_Output) .= $query->table({-border=>0},Tr(@button_list));

    # We have the main screen data and the navigation button data; display it and we're done.
    $Next_Action = "get it together";
}

if ($Next_Action eq "get it together") {
    print $query->header, start_html("Rob's Gaba Student Tracker");
    print $Button_Output;
    print $debug_msg if ($debug_on);
    print $Main_Body_Output;
    print $query->end_html;
}

sub processdata_add_reminder {
    ($debug_msg) .= $query->p("starting <b>processdata_add_reminder</b>:");
    ($debug_msg) .= $query->p("<br>parameters sent:");
    foreach my $key ($query->param) {
	($debug_msg) .= "<br>$key = " . $query->param("$key") . "\n";
    }

    my $instructorID = $query->param("instructorID");
    my $studentID = $query->param("studentID");
    my $reminder = $query->param("reminder");

    my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	|| die "Oops.  Could not connect to database: " . DBI->errstr;

    ($debug_msg) .= $query->p("adding <b>student_reminders</b> values (\"$instructorID\", \"$studentID\", \"$reminder\")");

    # insert each row that we created above
    my $sql = "replace into student_reminders values (\"$instructorID\",
                                                      \"$studentID\",
                                                      \"$reminder\")";
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    $dbh->disconnect;
    ($debug_msg) .= $query->p("Finished <b>processdata_add_reminder</b>");

}

sub write_add_reminder_screen {

    my $studentID = $query->param("studentID");
    my $instructorID = $query->param("instructorID");
    my $count;  # will count the rows returned by query
    my $reminder;  # will hold the reminder returned from query
    my $student_name;
    my $nashi;  # otherwise unused placeholder

    # look up the reminder
    unless ($instructorID eq "" || $studentID eq "") {
	my $sql_name_query = qq{
	    SELECT name
		from student_names
		where studentID = "$studentID"
	    };
	my $sql_reminder_query = qq{
	    SELECT reminder
		from student_reminders
		where studentID = "$studentID"
		and instructorID = "$instructorID"
	    };
	
	my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	    || die "Oops.  Could not connect to database: " . DBI->errstr;
	my $sth = $dbh->prepare($sql_name_query);
	$debug_msg .= $query->pre($sql_name_query);
	$sth->execute();
        $count =$sth->rows();
	($student_name) = $sth->fetchrow_array();

	$sth = $dbh->prepare($sql_reminder_query);
	$debug_msg .= $query->pre($sql_reminder_query);
	$sth->execute();
        $count =$sth->rows();
	($reminder) = $sth->fetchrow_array();
	$dbh->disconnect();
    } else {
	# error: studentID or instructorID not sent
	($Main_Body_Output) .= $query->p("Error: studentID or instructorID not sent");
	return;
    }

    # Draw the form to edit the reminder
    my $verb = ($count eq 1) ? "Edit the" : "Add a";
    $Main_Body_Output .= "\n<p>$verb reminder for $student_name ($studentID)</p>\n";
    # in the form below we have to specify the action or Perl will put all the URL-sent parameters on the action line
    ($Main_Body_Output) .= $query->p($query->start_form({-action=>"$gaba_tracker_pl"}) . $query->hidden({-name=>"studentID"}) . 
				     $query->hidden({-name=>"instructorID"}) . $query->textfield(-name=>"reminder", -size=>100, -maxlength=>300, -value=>"$reminder") . 
				     $query->submit({-name=>"button", -value=>"add reminder to DB"}) . $query->end_form);
}

sub write_add_instructor_screen {

    ($Main_Body_Output) .= $query->p("Add a new instructor to this system");

    ($Main_Body_Output) .= 
	$query->p("\n" . $query->start_form({-action=>"$gaba_tracker_pl"}) .
		  "\nInstructor's name: " . 
		  $query->textfield(-name=>'new_instructor_name',
				    -size=>40,
				    -maxlength=>40) .
		  "\n<br>Instructor's ID: " . 
		  $query->textfield(-name=>'new_instructorID',
				    -size=>10,
				    -maxlength=>10) .
		  "\n<br>Password: " . 
		  $query->password_field(-name=>'new_instructorPW',
					 -size=>20,
					 -maxlength=>20) .
		  "\n<br>Again: " . 
		  $query->password_field(-name=>'new_instructorPW2',
					 -size=>20,
					 -maxlength=>20) .
		  "\n<br>" . $query->submit(-name=>'button', -value=>'add instructor to DB') .
		  "\n<br>" . $query->reset(-name=>'clear',
					   -value=>'clear form') .
		  "\n" . $query->end_form
		  );

};

sub printreport_who {
    ($debug_msg) .= $query->p("Starting <b>printreport_who</b>:");

    my $sth;
    my ($count_todays_students,$count_prev_students,$count_future_students,$count_again_students,$count_bad_rows);

    if($query->param("date")) {
	$Todays_date = $query->param("date");
	$debug_msg .= "date = $Todays_date";
    }
	
    ($Main_Body_Output) .= $query->p($query->br("$instructor_name_logged_in"));

    # Select bad data and tell me abut it.
    my $sql_look_for_bad_data = qq{
	SELECT * from lessons_taught where
	    date = "0000-00-00" 
	    OR time = "00:00:00" 
	};

    # Select the students who we have today and who we've had before
    my $sql_had_before_query = qq{
	SELECT distinct L2.studentID, S.name, L2.instructorID, L2.date, L2.time, R.reminder
	    FROM lessons_taught L2, student_names S, lessons_taught L1
	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
						   AND L1.instructorID = R.instructorID)
	    WHERE (L1.studentID = L2.studentID
		   and L1.studentID = S.studentID
		   and L1.instructorID = "$instructorID_logged_in"
		   and L1.date < "$Todays_date")
	    and (L2.instructorID = "$instructorID_logged_in"
		 and L2.date = "$Todays_date")
	    and ((R.instructorID = "$instructorID_logged_in" and R.studentID = L1.studentID)
		 OR R.reminder IS NULL)
	    ORDER BY L2.date,L2.time
	};

    ($debug_msg) .= $query->p("Here is the query to select students had previously");
    ($debug_msg) .= $query->pre("$sql_had_before_query");

    my $sql_today_query = qq{
	SELECT L1.studentID, S.name, L1.instructorID, L1.date, L1.time, L1.choice, R.reminder
	    FROM lessons_taught L1, student_names S
	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
						   AND L1.instructorID = R.instructorID)
	    WHERE L1.studentID = S.studentID
	    and L1.date = "$Todays_date"
	    and L1.instructorID = "$instructorID_logged_in"
	    and ((R.instructorID = "$instructorID_logged_in" and R.studentID = L1.studentID)
		 OR R.reminder IS NULL)
	    ORDER BY date,time
 	};

    ($debug_msg) .= $query->p("Here is the query to select students from today");
    ($debug_msg) .= $query->pre("$sql_today_query");

    my $sql_future_query = qq{
	SELECT L1.studentID, S.name, L1.instructorID, L1.date, L1.time
	    FROM lessons_taught L1, student_names S
	    WHERE L1.studentID = S.studentID
	    and L1.date > "$Todays_date"
	    and L1.instructorID = "$instructorID_logged_in"
	};

    ($debug_msg) .= $query->p("Here is the query to select students we'll have later");
    ($debug_msg) .= $query->pre("$sql_future_query");

    # Select the students who we have today and we'll have again
    my $sql_have_again_query = qq{
	SELECT distinct L2.studentID, S.name, L2.instructorID, L1.date, L1.time, R.reminder
	    FROM lessons_taught L2, student_names S, lessons_taught L1
	         LEFT JOIN student_reminders R ON (L1.studentID = R.studentID
						   AND L1.instructorID = R.instructorID)
	    WHERE (L1.studentID = L2.studentID
		   and L1.studentID = S.studentID
		   and L1.instructorID = "$instructorID_logged_in"
		   and L1.date > "$Todays_date")
	    and (L2.instructorID = "$instructorID_logged_in"
		 and L2.date = "$Todays_date")
	    and ((R.instructorID = "$instructorID_logged_in" and R.studentID = L1.studentID)
		 OR R.reminder IS NULL)
	    ORDER BY date,time
	};

    ($debug_msg) .= $query->p("Here is the query to select students we'll have again");
    ($debug_msg) .= $query->pre("$sql_have_again_query");

# $$$ HERE
    my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	|| die "Oops.  Could not connect to database: " . DBI->errstr;

    $sth = $dbh->prepare ( $sql_look_for_bad_data );
    $sth->execute;
    $count_bad_rows = $sth->rows();
    my $naughty_naughty_zoot = $sth->fetchall_arrayref();

    $sth = $dbh->prepare ( $sql_had_before_query );
    $sth->execute;
    $count_prev_students = $sth->rows();
    my $had_before_results = $sth->fetchall_arrayref();

    $sth = $dbh->prepare ( $sql_today_query );
    $sth->execute;
    $count_todays_students = $sth->rows();
    my $today_results = $sth->fetchall_arrayref();

    $sth = $dbh->prepare ( $sql_future_query );
    $sth->execute;
    $count_future_students = $sth->rows();
    my $future_results = $sth->fetchall_arrayref();

    $sth = $dbh->prepare ( $sql_have_again_query );
    $sth->execute;
    $count_again_students = $sth->rows();
    my $again_results = $sth->fetchall_arrayref();

    $sth->finish();
    $dbh->disconnect();
    
    # Now create the report
    my ($n,$record,$studentID,$student_name,$instructorID,$date,$time,$choice,$reminder);

    if ($count_bad_rows) {
	($Main_Body_Output) .= $query->p("We just got some bad data!");
	foreach $record (@$naughty_naughty_zoot) {
	    my $crud;
	    foreach my $crizap (@$record) {
		$crud .= "~" . mkdef ($crizap);
	    }
	    ($Main_Body_Output) .= $query->br($crud);
	}  # end show bad rows
    }  # if bad rows

    # display students we have today
    ($Main_Body_Output) .= $query->p("These are the $count_todays_students students you have today. (* = chosen)");
    foreach $record (@$today_results) {
	# Parse each record array and display 

	($studentID, $student_name, $instructorID, $date, $time, $choice, $reminder) = @$record;
	($Main_Body_Output) .= $query->br . "$date $time " .
	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabaMain/lc/studentprofile_lessonrecord.asp?txtStudentID=$studentID",
		       -target=>"_blank"}, "$studentID $student_name");
	($Main_Body_Output) .= " *" if ($choice eq "true");
	($Main_Body_Output) .= " " . $query->a({-href=>"$gaba_tracker_pl?studentID=$studentID&instructorID=$instructorID_logged_in&button=add_reminder&date=$date"}, "edit");
	($Main_Body_Output) .= " " . mkdef($reminder);
    }

    # display students we have had before 
    ($Main_Body_Output) .= $query->p("These are the $count_prev_students students you've had before.");
    foreach $record (@$had_before_results) {
	# Parse each record array and display 
	($studentID, $student_name, $instructorID, $date, $time, $reminder) = @$record;
	($Main_Body_Output) .= $query->br . "$date $time " .
	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabamain/LC/alllessonrecords.asp?txtStudentID=$studentID",
		       -target=>"_blank"}, "$studentID $student_name");
	($Main_Body_Output) .= " " . $query->a({-href=>"$gaba_tracker_pl?studentID=$studentID&instructorID=$instructorID_logged_in&button=add_reminder"}, "edit");
	($Main_Body_Output) .= " " . mkdef($reminder);
    }

    ($Main_Body_Output) .= $query->p("You are scheduled to have <b>$count_future_students students</b> after today.");

    # display today's students that we'll have again
    ($Main_Body_Output) .= $query->p("Of today's students, you will have these soon.");
    foreach $record (@$again_results) {
	# Parse each record array and display 
	($studentID, $student_name, $instructorID, $date, $time, $reminder) = @$record;
	($Main_Body_Output) .= $query->br . "$date $time " .
	    $query->a({-href=>"http://gabaweb.gaba.co.jp/gabamain/LC/alllessonrecords.asp?txtStudentID=$studentID",
		       -target=>"_blank"}, "$studentID $student_name");
	($Main_Body_Output) .= " " . $query->a({-href=>"$gaba_tracker_pl?studentID=$studentID&instructorID=$instructorID_logged_in&button=add_reminder"}, "edit");
	($Main_Body_Output) .= " " . mkdef($reminder);
    }


}

sub processdata_add_instructor {

    # check to see if the passwords match
    if ($query->param("new_instructorPW") ne $query->param("new_instructorPW2")) {
	($Main_Body_Output) .= $query->p($query->b("passwords do not match.  Try again."));
    } else {
	($Main_Body_Output) .= $query->br("Adding " . $query->param("new_instructor_name"));

	$Main_Body_Output .= "<br>Please wait.\n";

	my $new_instructorID = $query->param("new_instructorID");
	my $new_instructorPW = $query->param("new_instructorPW");
	my $new_instructor_name = $query->param("new_instructor_name");

	my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	    || die "Oops.  Could not connect to database: " . DBI->errstr;

	# insert each row that we created above
        my $sql = "insert into instructor_names values ('$new_instructorID',
                                                        '$new_instructorPW',
                                                        '$new_instructor_name', '')";
	my $sth = $dbh->prepare($sql);
	$sth->execute;
	$dbh->disconnect;
	$Main_Body_Output .= "<br>Finished.\n";

    }
}

sub processdata_add_choices {
    my @input_buffer = split /\n+/, $query->param("input_data");
    my $input_buffer_instructorID;
    my @lessons_taught_output_rows;
    my @student_names_output_rows;
    my $record_counter = 0;
    my $nashi; # used as placeholder for unneeded data
    my (@times, @tds);
    my ($reportStartDate,$rptSYear,$rptSMonth,$rptSDate); # date range of the html report data entered

    # Read from instructor_names what instructorIDs we care to process
    my $sql_instructorID_query = 
	qq(SELECT instructorID from instructor_names;);
				    
    my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	|| die "Oops.  Could not connect to database: " . DBI->errstr;

    my $sth = $dbh->prepare ( $sql_instructorID_query );
    $sth->execute;
    my $instructorID_results = $sth->fetchall_arrayref();
    $sth->finish();
    $dbh->disconnect();
    
    my ($instructorIDs_bar_separator,$instructorIDs_comma_separator,@instructorIDs);

    # display students we have today
    foreach my $record (@$instructorID_results) {
	push (@instructorIDs, @$record);
    }

    $instructorIDs_bar_separator = join ("|", @instructorIDs);     # this is used in regex below
    $instructorIDs_comma_separator = join (", ", @instructorIDs);  # this is used in mySql code below
    $debug_msg .= "<br>We will look for these instructor IDs: $instructorIDs_comma_separator";
	
    my $attr_ref;  # will point to attributes inside tag
    my $tag_ref; # will point to tag and attributes

    my $START_TOKEN_PREFIX = "Token>";
    my $START_TEXT_PREFIX = "Text>";
    my $p = HTML::PullParser->new 
	( doc => $query->param("input_data"),
	  report_tags => [qw(td span)],                    # only care about these tags
	  start => "'$START_TOKEN_PREFIX', tagname, attr", # tell me the tagname and attributes when you see one
	  text => "'$START_TEXT_PREFIX', text"             # tell me the text between tags
	);

    # look for date and then look for times at the top of the table
    while ($tag_ref = $p->get_token) {
	unless ($reportStartDate) {
	    if ($$tag_ref[0] eq $START_TEXT_PREFIX && mkdef($$tag_ref[1]) =~ /DATE:/) {
		$tag_ref = $p->get_token;
		$reportStartDate = $$tag_ref[1];
		$Main_Body_Output .= "\n<p>Added student choices for $reportStartDate</p>\n";
		($rptSMonth,$rptSDate,$rptSYear) = split ("/", $reportStartDate);
	    }
	}
	if ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "td") {
	    $attr_ref = mkdef($$tag_ref[2]);
	    
	    # td tags with this class are the times at the top of the report
	    if (mkdef($$attr_ref{"class"}) eq "gabaBoxTitle") {
		my $time_ref= $p->get_token;
		push @times, $$time_ref[1];
	    }
	} elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "span") {
	    $p->unget_token($tag_ref);	    # put the span token back on so we can take it off in the next while loop
	    last;	                    # jump out of looking for times loop
	}
    } # end look for date and times

    $debug_msg .= "\n<p>These are the lesson times:\n<br>" . join (" - ", @times) . "</p>\n";

    while ($tag_ref = $p->get_token) {
	# instructorIDs are inside span tags
	if ($$tag_ref[0] eq $START_TOKEN_PREFIX && mkdef($$tag_ref[1]) eq "span") {
	    $attr_ref = mkdef($$tag_ref[2]);

	    # if the span tag has a title including an instructor we care about, then process it
	    if (mkdef($$attr_ref{"title"}) =~ /$instructorIDs_bar_separator/) {

		$debug_msg .= $query->br . "FOUND YOU" . join (":", %$attr_ref);
		my ($instructorID) = mkdef($$attr_ref{"title"}) =~ /\w*:\s(\d*)/;

		# count TDs
		my $count_TDs = -1;
		while ($tag_ref = $p->get_token) {

		    # if we're looking at a new instructor ID, then break out of this while loop
		    if ($$tag_ref[0] eq $START_TOKEN_PREFIX 
			&& mkdef($$tag_ref[1]) eq "span"
			&& mkdef($$tag_ref[2]{"title"}) =~ /InstructorID/
			) {
			$p->unget_token($tag_ref);	    # put the span token back on so we can take it off in the next while loop
			last;	                    # jump out of looking for times loop
		    } elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX 
			&& mkdef($$tag_ref[1]) eq "span") {
			$attr_ref = mkdef($$tag_ref[2]);
			my ($studentID) = mkdef($$attr_ref{"title"}) =~ /(\d*)/;
			my $choice = (mkdef($$attr_ref{"style"}) =~ /blue/) ? "true" : "false";

			if ($studentID) {
			    my $time = mkdef($times[$count_TDs]);
			    push (@lessons_taught_output_rows,
				  "insert into lessons_taught values ('$studentID','$instructorID','$rptSYear/$rptSMonth/$rptSDate','$time:00','$choice');");
			}
		    } elsif ($$tag_ref[0] eq $START_TOKEN_PREFIX 
			     && mkdef($$tag_ref[1]) eq "td") {
			$count_TDs++;
		    } # end tag is a TD
		} # end while counting TDs
	    } # end this is an instructor we care about
	} # end we are now looking at instructor schedules
    } # end processing HTML input

    # Next we will wipe pre-existing data for this instructor and date range and then add new records to db.
    my $delete_sql = "DELETE FROM lessons_taught WHERE date = \"$rptSYear/$rptSMonth/$rptSDate\" and instructorID IN ($instructorIDs_comma_separator);";

    $debug_msg .= $query->pre("$delete_sql");

    $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	|| die "Oops.  Could not connect to database: " . DBI->errstr;

    $sth = $dbh->prepare($delete_sql);
    $sth->execute;

    # process each row that we created above
    foreach my $sql (@lessons_taught_output_rows) {
	($debug_msg) .= $query->pre("$sql");
	my $sth = $dbh->prepare($sql);
	$sth->execute;
    }

    $sth->finish();
    $dbh->disconnect;

#    $Main_Body_Output .= "<br>$record_counter records inputted for dates $reportStartDate - $reportEndDate\n";

    $debug_msg .= "<br>end processing data for choices\n";

}

sub processdata_who {
    my @input_buffer = split /\n+/, $query->param("input_data");
    my $input_buffer_instructorID;
    my @lessons_taught_output_rows;
    my @student_names_output_rows;
    my $record_counter = 0;
    my $nashi; # used as placeholder for unneeded data
    my ($reportStartDate,$rptSYear,$rptSMonth,$rptSDate,$reportEndDate,$rptEYear,$rptEMonth,$rptEDate); # date range of the html report data entered

####  THESE CAN BE LOCAL TO THE LOOP BELOW, but it doesn't really matter, I guess.
    my ($month,$date,$year,$hour,$minute,$meridian,$studentID,$student_name,$instructorID);

    $debug_msg .= "<br>processing data for who\n";
    $debug_msg .= "<pre>\n";
    foreach (@input_buffer) {
	# figure out for what dates this report is being run
	if (/Student Lessons Scheduled for/) {
	    ($reportStartDate,$rptSMonth,$rptSDate,$rptSYear,$nashi,$reportEndDate,$rptEMonth,$rptEDate,$rptEYear) = 
		$_ =~ m|Student Lessons Scheduled for.\s+((\d+)/(\d+)/(\d+))(\s+-\s+((\d+)/(\d+)/(\d+)))*|;
	    ($rptEMonth,$rptEDate,$rptEYear,$reportEndDate) = ($rptSMonth,$rptSDate,$rptSYear,$reportStartDate) unless (defined $reportEndDate);
	}

	# figure out for what instructor this report is written
	if (/\[(\d+)\]/) {
	    $input_buffer_instructorID = $1;
	}

	if (/\d+\/\d+\/\d+\s+\d+:\d+.M/) {  # lines containing this text should be processed
	    $record_counter ++;
	    ($month,$date,$year,$hour,$minute,$meridian,$studentID,$student_name,$instructorID) = 
		$_ =~ m|(\d+)/(\d+)/(\d+)\s+(\d+):(\d+)(.M)\s+(\d+)\s+(\w+\s+\w+)\s+(\d+)|;

	    $date = substr("0$date",-2,2);      # force date to be 0 padded
	    $month = substr("0$month",-2,2);    # force month to be 0 padded
	    $studentID =substr("              $studentID",-$STUDENT_ID_LEN,$STUDENT_ID_LEN);  # force student ID to be padded with spaces
	    if ($meridian eq "PM" and $hour ne "12") {
		$hour += 12;                    # use military time
	    }

	    # put the data here so we can sql it in one loop outside this regex block
	    push (@lessons_taught_output_rows,"insert into lessons_taught values ('$studentID','$instructorID','$year/$month/$date','$hour:$minute:00','false');");
	    push (@student_names_output_rows,"insert ignore into student_names values ('$studentID','$student_name');");

#	    $debug_msg .=  "$month/$date/$year $hour:$minute $studentID $student_name $instructorID\n";
	}
    }
    $debug_msg .= "</pre>\n";

    # Now we have grabbed all the data we need from the input HTML.  
    # Below, we remove records from the date range we're about to insert.
    # That's because we are "mirroring" Gaba's DB; they might have removed a lesson since the last time we inserted

# $$$ HERE

    my $dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	|| die "Oops.  Could not connect to database: " . DBI->errstr;

    # Next we will wipe pre-existing data for this instructor and date range and then add new records to db.
    my $sql = "DELETE FROM lessons_taught WHERE date BETWEEN \"$rptSYear/$rptSMonth/$rptSDate\" and \"$rptEYear/$rptEMonth/$rptEDate\" and instructorID = $input_buffer_instructorID;";

    ($debug_msg) .= $query->p("Deleting records for instructor $input_buffer_instructorID for dates $reportStartDate - $reportEndDate");
    ($debug_msg) .= $query->pre("$sql");

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    # process each row that we created above
    foreach my $sql (@lessons_taught_output_rows) {
	($debug_msg) .= $query->pre("$sql");
	my $sth = $dbh->prepare($sql);
	$sth->execute;
    }

    # process each row that we created above
    foreach my $sql (@student_names_output_rows) {
	($debug_msg) .= $query->pre("$sql");
	my $sth = $dbh->prepare($sql);
	$sth->execute;
    }

    $dbh->disconnect;

    $Main_Body_Output .= "<br>$record_counter records inputted for dates $reportStartDate - $reportEndDate\n";

    $debug_msg .= "<br>end processing data for who\n";
}

sub look_for_input_data {

    $debug_msg .= "<p>Input data:";

    # for debugging params
    my @params = $query->param;
    foreach my $param (@params) { $debug_msg .= "<br>" . $param . "=" . $query->param("$param"); }

    # allowable Next_Actions:
    # (allow others by adding to elsif in main code above)
    $Next_Action = "printreport xx";
    $Next_Action = "processdata xx";
    # $Next_Action = "print default screen";   # this one has been handled
    
    if (mkdef($query->param("button")) eq "who") {
	$Next_Action = "printreport who";
    } elsif (mkdef($query->param("button")) eq "submit data") {
	# look at param input_data to see what data was inputted
	my $inputted_html = mkdef($query->param("input_data"));
	if ($inputted_html =~ m/Client Lesson Instructor Schedule/i) {
	    $Next_Action = "processdata who";
	} elsif ($inputted_html =~ m|<title>Learning Studio Lessons View</title>|i) {
	    $Next_Action = "add choices to db";
	} else {
	    $Next_Action = "complain about invalid data";
	}
    } elsif (mkdef($query->param("button")) eq "add_ID") {
	$Next_Action = "draw add instructor screen";
    } elsif (mkdef($query->param("button")) eq "add_reminder") {
	$Next_Action = "draw add reminder screen";
    } elsif (mkdef($query->param("button")) eq "add instructor to DB") {
	$Next_Action = "add instructor to db";
    } elsif (mkdef($query->param("button")) eq "add reminder to DB") {
	$Next_Action = "add reminder to db";
    } else {
	$debug_msg .= "<br>no input data found";
	$Next_Action = "print default screen";
    }

#    $debug_msg = "";  #  if this code starts to fuck up, remove this line

    # return $Next_Action to explain what to do next
    $Next_Action;
}


sub check_authentication {

    my (%cookies_read, $instructorID,$instructorPW,$Next_Action);
    my ($sth,$dbh);

    %cookies_read = fetch CGI::Cookie;

    $debug_msg .= "<p>Found these cookies:";
    foreach (keys %cookies_read) {
	$debug_msg .= "<br>$cookies_read{$_}";
    }


    # look for login-cookies.  Entered params supercede them.  "Logout" supercedes all.
    # big if: (even if they are logged in,) hitting logout supercedes any cookies
    if (mkdef($query->param("button")) eq "logout") {
	$instructorID = "delete";  $instructorPW = "delete";   # when set_cookies is run, these will be deleted
    } else {
	if (mkdef($query->param("instructorID"))) {
	    $instructorID = mkdef($query->param("instructorID"));
	} elsif ($cookies_read{'instructorID'}) {
	    $instructorID=$cookies_read{'instructorID'} -> value;
	} else {
	    $instructorID = "";
	}

	if (mkdef($query->param("instructorPW"))) {
	    $instructorPW = mkdef($query->param("instructorPW"));
	} elsif ($cookies_read{'instructorPW'}) {
	    $instructorPW=$cookies_read{'instructorPW'} -> value;
	} else {
	    $instructorPW = "";
	}
    }

    # assume we don't have valid credentials
    $Next_Action = "draw login screen";

    # This [unless] isn't needed to keep out anonymous visitors, but is added to make the code a bit faster
    unless ($instructorID eq "" || $instructorPW eq "") {
	my $sql_query = qq{ 
	    SELECT *
		FROM instructor_names
		WHERE instructorID = "$instructorID"
		and password = "$instructorPW" };
	
	$dbh = DBI->connect("DBI:mysql:database=$serverDatabase;host=$serverHostname",$serverUsername,$serverPassword)
	    || die "Oops.  Could not connect to database: " . DBI->errstr;
	$sth = $dbh->prepare($sql_query);
	$sth->execute;
	my $count_rows = $sth->rows();
	my $nashi;  # otherwise unused placeholder
	my $button_codes; # give special powers to certain users
	($instructorID_logged_in,$nashi,$instructor_name_logged_in,$button_codes) = $sth->fetchrow_array();
	$sth->finish();
	$dbh->disconnect();

	# a row with supplied credentials was found, so allow login to proceed
	if ($count_rows) {
	    $_temp_for_now_List_of_Buttons .= " $button_codes ";
## WTF?	    $instructor_name_logged_in .= " $count_rows";
	    $Next_Action = "look for input data";
	} else {
	    # the credentials sent didn't match anything, so delete the cookies
	    $instructorID = "delete";   # when set_cookies is run, $instructorID will be deleted
	    $instructorPW = "delete";   # when set_cookies is run, $instructorPW will be deleted
	    $Next_Action = "draw login screen";  # this is redundant but helps legibility
	}

	$cookie{'instructorID'} = $instructorID;
	$cookie{'instructorPW'} = $instructorPW;
	$debug_msg .= "<p>We just " . &setCookies(%cookie);
    }

#    $debug_msg = "";  #  if this code starts to fuck up, remove this line

    # return what we should do next ($Next_Action)
    $Next_Action;
}

sub mkdef {
    my($ival) = @_;

    if (defined $ival) {
	return $ival;
    } else {
	return "";
    }
}
