#!/usr/bin/perl -w
######################################################################
#
# daysold.pl allows users to determine how many days since their birthdate, 
# and then on what date they will be N days old
#
# Copyright (C) 2005-2006 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

require "allowSource.pl";
require "setCookies.pl";
require "draw_navigation.pl";
require "log_writer.pl";

use strict;
use CGI qw(:all fatalsToBrowser);
use CGI::Cookie;
use date_smurfer;
use mkdef;

my ($user,$name,$startDate,$startMonth,$startYear,$predict,%write_cookies,%read_cookies,%query_string_hash);
my $query = new CGI;
my $debug = 0;

my $daysold_log_output_line = "";

my %monthNumHash =
('01' => 'Jan',
 '02' => 'Feb',
 '03' => 'Mar',
 '04' => 'Apr',
 '05' => 'May',
 '06' => 'Jun',
 '07' => 'Jul',
 '08' => 'Aug',
 '09' => 'Sep',
 '10' => 'Oct',
 '11' => 'Nov',
 '12' => 'Dec');

my @monthNums = sort (keys (%monthNumHash));

my $title = "days old calculator";

%read_cookies = fetch CGI::Cookie;

if ($read_cookies{"name"}) {
    $name=$read_cookies{"name"} -> value;
}
if ($read_cookies{'startDate'}) {
    $startDate = $read_cookies{'startDate'} -> value;
}
if ($read_cookies{'startMonth'}) {
    $startMonth = $read_cookies{'startMonth'} -> value;
}
if ($read_cookies{'startYear'}) {
    $startYear = $read_cookies{'startYear'} -> value;
}
if ($read_cookies{'predict'}) {
    $predict = $read_cookies{'predict'} -> value;
}


my $cookiedough;
if ($query->param('calculate')) {
    if ($name = $query->param('name')) {
	$write_cookies{'name'} = $name;
    } else {
	$write_cookies{'name'} = 'deleted';
    }
    if ($startDate = $query->param('startDate')) {
	$write_cookies{'startDate'} = $startDate;
    } else {
	$write_cookies{'startDate'} = 'deleted';
    }
    if ($startMonth = $query->param('startMonth')) {
	$write_cookies{'startMonth'} = $startMonth;
    } else {
	$write_cookies{'startMonth'} = 'deleted';
    }
    if ($startYear = $query->param('startYear')) {
	$write_cookies{'startYear'} = $startYear;
    } else {
	$write_cookies{'startYear'} = 'deleted';
    }
    if ($predict = $query->param('predict')) {
	$write_cookies{'predict'} = $predict;
    } else {
	$write_cookies{'predict'} = 'deleted';
    }
    $cookiedough = &setCookies(%write_cookies);
}

$startYear = &mkdef($startYear);
$startMonth = &mkdef($startMonth);
$startDate = &mkdef($startDate);
$predict = &mkdef($predict);
$name = &mkdef($name);

print $query->header, $query->start_html($title);

&draw_navigation("0main&1daysold");

print "\n", $query->p($query->h3($title)), "\n";

$debug && print $query->p($query->b("construction  in progress; code may break."));

# $debug && print $query->p($cookiedough);

if ($name) {
    print $query->p("Hello, $name!");
}

my ($daysold, $form_instructions) = ("","");
if ($startYear && $startMonth && $startDate) {
    $daysold = &date_difference("$startYear/$startMonth/$startDate");
} 

print "\n<p>" . $query->start_form(-name=>'birthdate_form'), "<!-- we are sticking a big form around the table -->\n";
print "\n<table width='100%'><tr><td valign='top'><!--  BIG Table  start birthdate column -->\n";

if (&isInt($daysold)) {
    print $query->p("You are $daysold days old today!");

#    $daysold_log_output_line .= sprintf("%-20s",&mkdef($name));

    my @monthName = ('', 'January', 'February', 'March', 'April', 'May', 'June',
		     'July', 'August', 'September', 'October', 'November', 'December');

    $daysold_log_output_line .= sprintf("%23s", "$startDate $monthName[$startMonth] $startYear => ");
    $daysold_log_output_line .= sprintf("%-8s",&mkdef($daysold));
    $form_instructions = "Enter another birthdate:";
}
else
{
    # &date_difference returned something other than a number, i.e. an error.  Print that error
    print $query->p("$daysold");
    $form_instructions = "Enter your birthdate:";
}

&draw_bday_form_fields;

print "\n</td><!--  BIG Table end birthdate column -->\n";

if (&isInt($daysold)) {
    print "\n<td valign='top'><!--  BIG Table  start predict column -->\n"; 
    if ($predict) {
	my $Nth_date = &date_plus_days("$startYear/$startMonth/$startDate&$predict");
	print $query->p("Your ",  $predict . "th day: $Nth_date!");

	$daysold_log_output_line .= sprintf("%8s => ",&mkdef($predict));
	$daysold_log_output_line .= sprintf("%-20s",&mkdef($Nth_date));

    }
    # &date_difference returned a number for daysold; let them predict their Nth day
    &draw_predict_form_fields;
    print "\n</td><!--  BIG Table end predict column -->\n";
}

print "</tr></table><!-- end  Big Table -->\n";
print $query->end_form . "</p>\n";

&write_log("daysold",$daysold_log_output_line);
&allowSource;

print $query->end_html;

sub isInt {
    my $num_in = shift;
    if (&mkdef($num_in) !~ /^-?[0-9]+$/) {
        return 0;
    }
    else
    {
        return 1;
    }
}

sub draw_predict_form_fields {
    print $query->p( "When will I be \n", 
		     $query->textfield(-name=>'predict',-size=>5,-maxlength=>5,-default=>"$predict"), "\n",
		     " days old?\n",
		     $query->br($query->submit(-name=>'calculate', -value=>'Show my Nth day!'), "\n"));
}

sub draw_bday_form_fields {
    print $query->p($form_instructions), "\n";

    print $query->p( # $query->hidden(-name=>'predict', -default=>["$predict"]), "\n",
		     $query->br, "DD Month YYYY",
		     $query->br, $query->textfield(-name=>'startDate',-size=>2,-maxlength=>2,-default=>"$startDate"), "\n",
		     $query->popup_menu(-name=>'startMonth',
					-values=>\@monthNums,
					-default=>"$startMonth",
					-labels=>\%monthNumHash),
		     $query->textfield(-name=>'startYear',-size=>4,-maxlength=>4,-default=>"$startYear"), "\n",

		     $query->p("name", $query->textfield(-name=>'name',-size=>12,-maxlength=>100,-default=>"$name")), "\n",

		     $query->submit(-name=>'calculate', -value=>'How old am I?'), "\n");
}

# now uses log_writer.plsub write_daysold_log {
# now uses log_writer.pl    open THE_OUTPUT_FILE, ">>$daysold_log_filename" or die "can't open $daysold_log_filename: $!";
# now uses log_writer.pl    print THE_OUTPUT_FILE $daysold_log_output_line;
# now uses log_writer.pl    print THE_OUTPUT_FILE sprintf("%-50s",$ENV{'REMOTE_HOST'});
# now uses log_writer.pl    print THE_OUTPUT_FILE "\n";
# now uses log_writer.pl    close THE_OUTPUT_FILE;
# now uses log_writer.pl}
