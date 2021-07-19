#!/usr/bin/perl -w
######################################################################
#
# rob_first_AJAX.pl, modified from http://perljax.us example
# http://www.perljax.us/demo/pjx_cr.pl
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

######################################################################
#
# this is an example script of how you would use coderefs to define
# your CGI::Ajax functions.
#
# NB The CGI::Ajax object must come AFTER the coderefs are declared.
#
######################################################################

use lib "/home/barefoot_rob/lib/perl5/site_perl/";  # to use modules installed in my user space (in this case CGI::Ajax)
use strict;
use CGI::Ajax;
use CGI;
use Switch;
require "allowSource.pl";
require "mkdef.pl";

my $q = new CGI;

my $adder = sub {
    my $output;
    my ($value_a, $value_b, $operator) = @_;
    $value_a = "" if not defined $value_a; # make sure there's def
    $value_b = "" if not defined $value_b; # make sure there's def

    if ( $value_a =~ /\D+/ or $value_a eq "" ) {
	$output .= $value_a . " and " . $value_b;
    } elsif ( $value_b =~ /\D+/ or $value_b eq "" ) {
	mkdef($value_b);
	for (my $i=0;$i<$value_a;$i++) {
	    $output .= $value_b;
	}
    } else {
	# got two numbers, so smurf them
	$output = join(" ", $value_a, $operator, $value_b) . " = ";
	switch ($operator) {
	    case "plus" {$output .= $value_a + $value_b}
	    case "minus" {$output .= $value_a - $value_b}
	    case "groks" {$output .= $value_a / $value_b}
	    case "times" {$output .= $value_a * $value_b}
	}
    }
    return $output;
};


my $Show_Form = sub {

  my %labels = ('plus'=>'+',
		'minus'=>'-',
		'groks'=>'/',
		'times'=>'*'
		);
  my @names = keys(%labels);
  my $html = "";
  $html .= $q->start_html("rob example") . "\n";
  $html .= $q->start_form(-name=>"larry");
  $html .= "\n" . $q->p("Enter something (preferably a number):", 
			$q->textfield({id=>"cat", name=>"joe", -size=>"5", -maxlength=>"4", onkeyup=>"adder( ['cat','dog','op'], ['resultdiv'] ); return true;"})) . "\n";
  $html .= "\n" . $q->p("Enter something else:", 
			$q->textfield({id=>"dog", name=>"joke", -size=>"5", -maxlength=>"4", onkeyup=>"adder( ['cat','dog','op'], ['resultdiv'] ); return true;"})) . "\n";
  $html .= $q->hr;
  $html .= $q->end_form;
  $html .= $q->start_form(-name=>"dilbert");
  $html .= "\n" . $q->p("Note this <em>numeric</em> operator thing is in a different form:",
			$q->popup_menu(-onChange=>"adder( ['cat','dog','op'], ['resultdiv'] ); return true;",
				       -id=>'op',
				       -name=>'menu_name',
				       -values=>\@names,
				       -default=>'multiply',
				       -labels=>\%labels)) . "\n";
  $html .= $q->end_form;
  $html .= $q->start_div({id=>"resultdiv", style=>"border: 1px solid black; width: 740px; height: 220px; overflow: auto"});
  $html .= $q->end_div . "\n";  # for some reason if it's a <div /> tag, the remaining html gets printed on top, at least in Firefox 1.5.0.4
  $html .= &allowAjaxSource;
  $html .= $q->end_html;
  return $html;
};

my $pjx = CGI::Ajax->new( 'adder' => $adder);
print $pjx->build_html($q,$Show_Form); # this outputs the html for the page
