# date_smurfer.pm
######################################################################
#
# date_smufer: a set of date utilites that do simple date calculations
# 
# 
#
# Copyright 2005 Rob Nugen
# Feel free to copy this and change it, so long as you give me
# appropriate credit, document your changes, and make the source
# available to whoever wants it. http://robnugen.com/copyright.html
#
######################################################################

package date_smurfer;

##  I don't know how ths works, but I understand I need to put the names of functions I want to use in the @EXPORT array
use Exporter ();
@ISA = qw(Exporter);
@EXPORT = qw(date_difference date_plus_days);

use strict;
use Time::Local;
use mkdef;

# require "mkdef.pl";

# I imagine I should make a date object and tell it how to do things
# instead of having millions of parameters to the functions, but I
# don't know how to make objects in perl, and I think I can just brute
# force this code.  So there.

my %monthNum =
('Jan' => '01',
 'Feb' => '02',
 'Mar' => '03',
 'Apr' => '04',
 'May' => '05',
 'Jun' => '06',
 'Jul' => '07',
 'Aug' => '08',
 'Sep' => '09',
 'Oct' => '10',
 'Nov' => '11',
 'Dec' => '12'); 

my @daysInMonths = (0,31,0,31,30,31,30,31,31,30,31,30,31);  # start with 0 to make January's array index be 1

sub date_difference {

    my ($start_date,$end_date,$debug) = split (/&/, $_[0]);
    my ($sYear,$sMonth,$sDate) = split (/\//, $start_date);
    my ($eYear,$eMonth,$eDate) = split (/\//, &mkdef($end_date));

    unless (isDate($sYear,$sMonth,$sDate)) {
        return ("'$sYear/$sMonth/$sDate' is not a valid date.");
    }

    unless (isDate($eYear,$eMonth,$eDate)) {
	# use system date for end date
	my ($full_date, $sysMonthAbbrev);
	$full_date= `date`;
	(undef,$sysMonthAbbrev,$eDate,undef,undef,$eYear) = split(' ',$full_date);

	$eMonth = $monthNum{$sysMonthAbbrev};
    }

    my $debug_string = $debug ? "($eYear/$eMonth/$eDate - $sYear/$sMonth/$sDate) = " : "";
    return ($debug_string . &calculateDaysOld($sYear,$sMonth,$sDate,$eYear,$eMonth,$eDate));

}

sub date_plus_days {
    my ($start_date,$delta_days,$debug) = split (/&/, $_[0]);
    my ($sYear,$sMonth,$sDate) = split (/\//, $start_date);
    my ($eYear,$eMonth,$eDate) = ($sYear,$sMonth,$sDate);    # we will bump $e____ variables until we reach the correct date.

    unless (isDate($sYear,$sMonth,$sDate)) {
        return ("'$sYear/$sMonth/$sDate' is not a valid date.");
    }

    unless (isInt($delta_days)) {
        return ("We can't add $delta_days to a date.");
    }

    &setFeb($eYear);
    &incDate(\$eYear,\$eMonth,\$eDate,$delta_days);

    # I put a '' as the zeroth element, so $monthName[1] means January
    my @monthName = ('', 'January', 'February', 'March', 'April', 'May', 'June',
		     'July', 'August', 'September', 'October', 'November', 'December');

    my $debug_string = $debug ? "($sYear/$sMonth/$sDate  + ($delta_days)) = " : "";
    return ($debug_string . "$eDate $monthName[$eMonth] $eYear");

};

sub incDate {
    my ($year, $month, $date, $add) = @_;

    $$date += $add;

    # now check to see if we went over $month length
    while ($$date > $daysInMonths[$$month]) {
	$$date -=  $daysInMonths[$$month];
	&incMonth($year, $month,1);
    }
    # now check to see if we went under 1
    while ($$date < 1) {
	&incMonth($year, $month, -1);
	$$date +=  $daysInMonths[$$month];
    }
}

sub incMonth {
    my ($year, $month, $add) = @_;
    $$month += $add;
    while ($$month > 12) {
	$$month -= 12;    # if $add put $$month == 15, it will become 3
	&incYear($year,1);  # pointer to year, as sent to &incMonth
    }
    while ($$month < 1) {
	$$month += 12;    # if $add put $$month == -2, it will become 10
	&incYear($year,-1);  # pointer to year, as sent to &incMonth
    }
}

sub incYear {
    my ($year, $add) = @_;
    $$year += $add;
    &setFeb($$year);
}

##################################################################
#
# Sub Name: isDate
#
# Description: This checks to make sure the input values make a valid date
#
##################################################################
sub isDate {
    my ($year,$month,$date) = @_;

    $year = &mkdef($year);
    $month = &mkdef($month);
    $date = &mkdef($date);

    if (isInt($year) && isInt($month) && isInt($date)) {

	# We have some numbers; need to see if they can make a date
	
	&setFeb($year);
	if ((1580 < $year) && ($year < 10000) && (0 < $month) && ($month < 13) && (0 < $date) && ($date <= $daysInMonths[$month])) {
	    return (1);
	}
	else
	{
	    return (0);
	}
    }
    else
    {
	return (0);
    }
}

##################################################################
#
# Sub Name: isInt
#
# Description: This sub validates the input to check to see if the
# input is an integer without commas.  I'm only using this for dates
# and numbers of days.  No commas.  No points, but an optional
# beginning hyphen is okay.
#
##################################################################
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

sub isLeap {
    my ($year) = @_;

    $year = &mkdef($year);

    if ($year % 4 == 0) {
	if ($year % 100 == 0) {
	    if ($year % 400 == 0) {
		1;
	    }
	    else {
		0;
	    }
	}
	else {
	    1;
	}
    }
    else {
	0;
    }
}

sub calculateDaysOld
{
    my ($startYear,$startMonth,$startDate,$stopYear,$stopMonth,$stopDate) = @_;

    my $days = 0;

    if($startYear > $stopYear) {
	# swap the two if start exceeds stop;
	($startYear,$stopYear) = ($stopYear, $startYear);
	($startMonth,$stopMonth) = ($stopMonth, $startMonth);
	($startDate,$stopDate) = ($stopDate, $startDate);
    }

    # $startYear <= $stopYear

    if($startYear < $stopYear) {
	$days = &daysRemainingInYear($startDate, $startMonth, $startYear);

	$days += &daysSoFarInYear($stopDate, $stopMonth, $stopYear);

	my $startYearPlusOne = $startYear + 1;
	my $stopYearMinusOne = $stopYear - 1;
	if ($startYearPlusOne <= $stopYearMinusOne) {
	    $days += &daysInYearRange($startYearPlusOne,$stopYearMinusOne);
	}
    } else {
	# $startYear == $stopYear

	if($startMonth > $stopMonth) {
	    # swap the two if start exceeds stop;
	    ($startMonth,$stopMonth) = ($stopMonth, $startMonth);
	    ($startDate,$stopDate) = ($stopDate, $startDate);
	}

	if($startMonth < $stopMonth) {
	    $days = &daysRemainingInMonth($startDate, $startMonth, $startYear);
	    my $startMonthPlusOne = $startMonth + 1;
	    my $stopMonthMinusOne = $stopMonth - 1;
	    if ($startMonthPlusOne <= $stopMonthMinusOne) {
		$days += &daysInMonthRange($startMonthPlusOne,$stopMonthMinusOne,$startYear);
	    }

	    $days += $stopDate;  # $stopDate is daysSoFarInMonth

	} else {
	    # $startMonth == $stopMonth
	    if($startDate > $stopDate) {
		# swap the two if start exceeds stop;
		($startDate,$stopDate) = ($stopDate, $startDate);
	    }
	    $days = $stopDate - $startDate;
	}
    }
    $days;
}

sub daysRemainingInMonth {
    my ($startDate, $startMonth, $startYear) = @_;

    my $days = 0;

    &setFeb($startYear);

    $days = ($daysInMonths[$startMonth]-$startDate);  # add remaining days in month
}

sub setFeb {
    my ($year) = @_;
    $daysInMonths[2] = isLeap($year) ? 29 : 28;
}

sub daysInMonthRange {
    my ($startMonth, $stopMonth, $year) = @_;

    my ($days,$month);

    &setFeb($year);

    $month=$startMonth;

    do {
	$days += $daysInMonths[$month];
	$month += 1;
    } while ($month <= $stopMonth);

    $days;  # $days is returned;
}

sub daysRemainingInYear {
    my ($startDate, $startMonth, $startYear) = @_;

    my $days = 0;

    &setFeb($startYear);

    $days += ($daysInMonths[$startMonth]-$startDate);  # add remaining days in current month

    while($startMonth < 12) {
	$startMonth += 1; # go to next month
	$days += $daysInMonths[$startMonth];
    } 

    $days;
}

sub daysSoFarInYear {
    my ($endDay, $endMonth, $endYear) = @_;

    my $days = 0;

    &setFeb($endYear);

    $days += $endDay;  # days so far in month

    while($endMonth > 1) {
	$endMonth -= 1; # go to previous month
	$days += $daysInMonths[$endMonth];
    } 
    $days;
}

sub daysInYearRange {
    my ($startYear, $stopYear) = @_;

    my ($days,$year);

    $year=$startYear;

    do {
	$days += &daysInYear($year);
	$year += 1;
    } while ($year <= $stopYear);

    $days;  # $days is returned;
}

sub daysInYear {
    my ($year) = @_;
    &isLeap($year) ? 366 : 365;
}
1;
