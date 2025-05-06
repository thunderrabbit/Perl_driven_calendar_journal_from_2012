#!/usr/bin/perl -w

$more_years_prefix = "/journal/journal.pl?date=";

sub sidebar {
  ($date,$ls1rfile) = @_;

  undef $/;      # file slurp mode
  open LSONER, $ls1rfile;
  $ls1r = <LSONER>;
  $/ = "\n";  # unslurp mode

   unless ($date =~ m!^\d\d\d\d(?:/|$)!m)
   {
       # if date does not start with a four digit year, then grab the Latest Date as defined in the ls1R.html file
       ($date) = $ls1r =~ m/LATEST ENTRY DATE: (.*)/m;
   }

  ($year, $month, $day) = split /\//, $date;
  $debug && print "IN sidebar:<br>date = $date: <br>year: $year<br>month: $month<br>day: $day\n\n";

  # We should note that naturally this code is pretty heavily dependent
  # upon the format of the ls-1R.html file.  Here is a brief description
  # of that format as it stands on 9:45am Tuesday 6 July 2002:
  #
  # * A list of year summaries
  #     (The summaries are required to be in numerical order.)
  #      The summaries look like this:
  #
  #      $year:
  #      <!-- exactly the HTML code that should be put on the page
  #           to show the year summary, terminated by a blank line,
  #           that is, something matching "\n\n" -->
  #
  #      Presently, the colon after the year is followed by one or
  #      more spaces and a newline, but in the future I may put
  #      other information in between the colon and newline.
  #      (For instance, the next and previous years that exist, if any.)
  #      Tabs should not be used except possibly within the month
  #      and year summaries themselves.
  #
  # * A list of month summaries
  #      (The order of the month summaries is the same as for the year
  #       summaries.)
  #
  #      $year/$month:
  #      <!-- exactly the HTML code that should be put on the page
  #           to show the month summary, terminated by a blank line
  #      -->
  #
  #      The note about the colon for year summaries goes also for
  #      month summaries.
  ###


  ## Here's what we will do:
  # print next year summary
  # print this year summary
  # print next month summary
  # print this month summary
  # print previous month summary
  # print previous year summary
  # print "main" link (aka year listing?)
  # print search link?

  #------------------------------------------
  # get years in the journal
  ($years) = $ls1r =~ m/^YEARS: *(.*)?/m;
  ($more_last_years, $lastyear, $nextyear, $more_next_years) =
    $years =~ m/
      #      2+yrs_ago        prev_yr
      (?:(?:(\d\d\d\d),\ *)?(\d\d\d\d),\ *)?
      $year
      (?:,\ *(\d\d\d\d)(?:,\ *(\d\d\d\d))?)?
      #      next_yr         next_2+yrs
    /x;
    # (?:  ) is a non-capturing set of parentheses.
    # The non-capturing is important because I think that if the
    # outside parentheses don't match, the variables that correspond
    # to the inside parentheses become undef, not just "".

   if ($nextyear eq "" && $lastyear eq "") {
      # if there's no last year and no next year then we have chosen
      # an invalid year (cause I know there are more than 2 years available)

      ($date) = $ls1r =~ m/LATEST ENTRY DATE: (.*)/m;
      ($year, $month, $day) = split /\//, $date;
   }

  $debug && print "<p>IN SIDEBAR: years = $years\n<br> last year = $lastyear\n";
  $debug && print "<br>year = $year\n<br> next year = $nextyear\n";

  # get months in the journal
  ($months) = $ls1r =~ m/^MONTHS $year: *(.*)?/m;
  if ($month eq "") {
      # if month was unspecified, then default to last month of the year.
      ($month) = $months =~ m/(\d\d)$/m;
  }

  ($more_last_months, $lastmonth, $nextmonth, $more_next_months) =
    $months =~ m/
      (?:(?:(\d\d),\ *)?(\d\d),\ *)?
      $month
      (?:,\ *(\d\d)(?:,\ *(\d\d))?)?
    /x;

  if ($lastmonth eq "" && $nextmonth eq "") {
      # if month was invalid, then default to last month of the year.
      ($month) = $months =~ m/(\d\d)$/m;
  }

  $debug && print "<p>IN SIDEBAR: months = $months\n<br>last month = $lastmonth\n</p>";
  $debug && print "<p>IN SIDEBAR: month = $month\n<br> next month = $nextmonth\n</p>";

  # get days in the journal
  ($days) = $ls1r =~ m|^DAYS $year/$month:\ *(.*)?|m;
  if ($day eq "") {
      # if day was unspecified, then default to last day of the month.
      ($day) = $days =~ m/(\d\d)$/m;
  }
  ($more_last_days, $lastday, $nextday, $more_next_days) =
    $days =~ m/
      (?:(?:(\d\d),\ *)?(\d\d),\ *)?
      $day
      (?:,\ *(\d\d)(?:,\ *(\d\d))?)?
    /x;

  if ($lastday eq "" && $nextday eq "") {
      # if day was invalid, then default to last day of the month.
      ($day) = $days =~ m/(\d\d)$/m;
  }

  $debug && print "<p>IN SIDEBAR: days = $days\n<br>last day = $lastday\n</p>";
  $debug && print "<p>IN SIDEBAR: day = $day\n<br> next day = $nextday\n</p>";
  #----------------------------------------

  #-----------------------
  # Here we will convert the month variables into YYYY/MM format,
  # filling in the empty variables in the special cases
	# where we wrap to the next or previous year.
  if($month) {
    $month = "$year/$month";

    if($nextmonth) {
      $nextmonth = "$year/$nextmonth";
    } else {
      # look for first month in $nextyear
      if($nextyear) {
        ($firstmonth_nextyear) = $ls1r =~ m/^MONTHS $nextyear:\ *(\d\d)?/m;
        $debug && print "<p>first month in next year = $firstmonth_nextyear\n</p>";
        $nextmonth = "$nextyear/$firstmonth_nextyear";
      }
      # else no months after this with journal entries in any year.
      # $nextmonth will remain empty/undefined.
    }

    if($lastmonth) {
      $lastmonth = "$year/$lastmonth";
    } else {
      # look for final month in $lastyear
      if($lastyear) {
        ($finalmonth_lastyear) = $ls1r =~ m/^MONTHS $lastyear:.*?(\d\d)?$/m;
        $debug && print "<p>final month in last year = $finalmonth_lastyear\n</p>";
        $lastmonth = "$lastyear/$finalmonth_lastyear";
      }
      # else no months before this with journal entries in any year.
      # $lastmonth will remain empty/undefined.
    }
  }

  # Note that all month variables include the year.
  if($day) {
    $day = "$month/$day";

    if($nextday) {
      $nextday = "$month/$nextday";
    } else {
      # look for first day in $nextmonth
      if($nextmonth) {
        ($firstday_nextmonth) = $ls1r =~ m/^DAYS $nextmonth:\ *(\d\d)?/m;
        $debug && print "<p>first day in next month = $firstday_nextmonth\n</p>";
        $nextday = "$nextmonth/$firstday_nextmonth";
      }
      # else no days after this with journal entries in any month.
      # $nextday will remain empty/undefined.
    }

    if($lastday) {
      $lastday = "$month/$lastday";
    } else {
      # look for final day in $lastmonth
      if($lastmonth) {
        ($finalday_lastmonth) = $ls1r =~ m/^DAYS $lastmonth:.*?(\d\d)?$/m;
        $debug && print "<p>final day in last month = $finalday_lastmonth\n</p>";
        $lastday = "$lastmonth/$finalday_lastmonth";
      }
      # else no days before this with journal entries in any month.
      # $lastday will remain empty/undefined.
    }
  }

  ($first_entry_date) = $ls1r =~ m/FIRST ENTRY DATE: (.*)/m;
  ($latest_entry_date) = $ls1r =~ m/LATEST ENTRY DATE: (.*)/m;

  #----------------------

  # I put last month at the top because I found it confusing to have the
  # days in each month read top to bottom, but then to have the following
  # month be above that.  I like reverse chronological better, but not at
  # the expense of continuity.  Everything should still be visible with any
  # reasonable browser window and font size.

  # Note that all date variables are fully defined.
#  print '<p><a href="http://www.nanowrimo.org/eng/user/260012"><img src="http://www.nanowrimo.org/NanowrimoUtils/NanowrimoMiniGraph/260012.png" /></a></p>';
  if($lastmonth) {
      $ls1r =~ m!^$lastmonth:\ *$(.*?\n\n)!ms;
      print $1;
  } else {
      $ls1r =~ m!^NO prev MONTH:\ *$(.*?\n\n)!ms;
      print $1;
  }
  if($month) {
    print "\n<table class=\"highlighted_calendar\"><tr><td>\n";
    $ls1r =~ m!^$month:\ *$(.*?\n\n)!ms;
    print $1;
    print "\n</td></tr></table>\n";
  }
  if($nextmonth) {
    $ls1r =~ m!^$nextmonth:\ *$(.*?\n\n)!ms;
    print $1;
  } else {
      $ls1r =~ m!^NO next MONTH:\ *$(.*?\n\n)!ms;
      print $1;
  }
  if($lastyear)  {
    $ls1r =~ m!^$lastyear:\ *$(.*?\n\n)!ms;
    print $1;
  } else {
      $ls1r =~ m!^NO prev YEAR:\ *$(.*?\n\n)!ms;
      print $1;
  }
  if($year) {
    print "\n<table class=\"highlighted_calendar\"><tr><td>\n";
    $ls1r =~ m!^$year:\ *$(.*?\n\n)!ms;
    print $1;
    print "\n</td></tr></table>\n";
    }
  if($nextyear) {
    $ls1r =~ m!^$nextyear:\ *$(.*?\n\n)!ms;
    print $1;
  } else {
      $ls1r =~ m!^NO next YEAR:\ *$(.*?\n\n)!ms;
      print $1;
  }

print "<pre class='calendar'>&nbsp;&nbsp;";
unless($date eq $first_entry_date) {
    print "<a href='$journal_pl?type=$journal_type&amp;date=$first_entry_date' title='earliest entry'>|&lt;</a>&nbsp;";
} else {
    print "|&lt;&nbsp;";
}
  if($more_last_years) {
     print "<a href='$journal_pl?type=$journal_type&amp;date=$more_last_years' title='$more_last_years'>&lt;&lt;</a>&nbsp;";
  } else {
    print "&lt;&lt;&nbsp;";
  }
  print "more";
  if($more_next_years) {
    print "&nbsp;<a href='$journal_pl?type=$journal_type&amp;date=$more_next_years' title='$more_next_years'>&gt;&gt;</a> ";
  } else {
    print "&nbsp;&gt;&gt;";
  }

unless($date eq $latest_entry_date) {
    print "&nbsp;<a href='$journal_pl?type=$journal_type&amp;date=$latest_entry_date' title='most recent entry'>&gt;|</a>";
} else {
    print "&nbsp;&gt;|";
}
print "</pre>";
  #"main" link (aka year listing?)
  #search link?

print "\n";

# <p><a href="http://www.nanowrimo.org/NanowrimoUtils/ProgressReport/260012.html"><img src="http://www.nanowrimo.org/NanowrimoUtils/NanowrimoGraph/260012.png" /></a>
# <br/>Click for my detailed 2008 <a href="http://www.nanowrimo.org/">NaNoWriMo</a> stats!</p>


}

1;
