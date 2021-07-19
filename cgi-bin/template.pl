#!/usr/bin/perl -w

######################################################################
#
# template.pl is just a bit of code to make other bits of code more easily

# Copyright (C) 2005-2006 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

require "allowSource.pl";
require "setCookies.pl";
require "mkdef.pl";

## daysold.pl does a decent job of handling cookies, parameters and form fields

use lib "/home/barefoot_rob/perlmods/share/perl";  # to use modules installed in my user space (in this case Ajax)
use strict;
use CGI;
use CGI::Ajax;
use CGI::Cookie;
use Error;

my ($env_var,$user,$pass,$name,%write_cookies,%read_cookies,%query_string_hash);
my $query = new CGI;

%read_cookies = fetch CGI::Cookie;

if ($read_cookies{"user"}) {
    $name=$read_cookies{"user"} -> value;
}
if ($read_cookies{"pass"}) {
    $name=$read_cookies{"pass"} -> value;
}

my $cookiedough;

if ($query->param('name')) {
    if ($user = $query->param('user')) {
	$write_cookies{'user'} = $user;
    } else {
	$write_cookies{'user'} = 'deleted';
    }
    if ($pass = $query->param('pass')) {
	$write_cookies{'pass'} = $pass;
    } else {
	$write_cookies{'pass'} = 'deleted';
    }
    $cookiedough = &setCookies(%write_cookies);
}

print $query->header, $query->start_html("title");

print $query->h3("h3"), "\n";

print $query->p("Wassap"), "\n";

print $query->p( $query->start_form(-name=>'form1'), "\n",

#		     $query->popup_menu(-name=>'imageSelectList',
#					-values=>\@image_list,
#					-onChange=>'form1.image.click()'),
		 $query->p("user", $query->textfield(-name=>'user',-size=>12)), "\n",
		 $query->p("pass", $query->password_field(-name=>'pass',-size=>12)), "\n",

		 $query->textarea(-name=>'text_area',
				  -default=>'wassap!',
				  -rows=>10,
				  -columns=>50), "\n",
		 $query->submit(-name=>'name', -value=>'value'), "\n",
		 $query->end_form);

if ($user = $query->param('user')) {
    print $query->p("user = $user"), "\n";
}

if ($pass = $query->param('pass')) {
    print $query->p("pass = $pass"), "\n";
}

my $query_string = $ENV{'QUERY_STRING'};
undef %query_string_hash;

# Split the name-value pairs
my @pairs = split(/&/, $query_string);

foreach my $pair (@pairs) {
    my ($name, $value) = split(/=/, $pair);

    # Translate plus signs and %-encoding
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    $query_string_hash{$name} = $value;
}

foreach my $key (keys %query_string_hash) {
    print $query->p("$key = ", $query->b($query_string_hash{$key}));
}

foreach $env_var (keys %ENV) {
    print $query->br("$env_var</B> = $ENV{$env_var}"), "\n";
}

&allowSource;

print $query->end_html;
