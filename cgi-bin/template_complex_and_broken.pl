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

# load in the modules
use lib "/home/barefoot_rob/perlmods/share/perl";  # to use modules installed in my user space (in this case Ajax)
use strict;
use CGI;
use CGI::Ajax;
use CGI::Cookie;
use Error qw(:try);

######################################################################
#
# This is the shortest technique I found to create my own errors.
# Note two occurences of object name on each line, and "package main"
# after all the definitions
#
######################################################################
package Critical_error;     @Critical_error::ISA = qw(Error);
package main;

require "mkdef.pl";
require "allowSource.pl";
require "DB_CDE.pl";  #  DBI code from Mike Schienle
require "setCookies.pl";


my $q = new CGI;      # will be used for params, cookies, Ajax, html output

my $action;  # this will be set initially after we do crititcal_settings_check and check_tables_in_db

my %system_status; # this will tell us what we can do in the main menu.  (what tables are available for search?, is the admin logged in? ..)

# general settings for images, output language, and db access are stored in text files that will be read into hashes, starting with %settings
my ($settings_file,%settings,%lang,%dbHash);
$settings_file = "/home/barefoot_rob/setup_journal/images.settings";

try {
    &critical_settings_check;
#    &check_tables_in_db;
}
catch Critical_error with { &critical_error_handler }

otherwise {
    warn ("images is in otherwise-BLOCK, which means we didn't catch the error above.");
    my $err = shift;
    warn ("caught the culprit; looks like ", $err->{"-text"});
    exit;
}
finally {
};

# DBI handles
my ($sth, $sql, $rv, $dbh, $dbData);

my $pjx = CGI::Ajax->new( 
			  'tag_search' => \&tag_search,
			  'main_fart' => \&main_fart

);

my $ajax_javascript_debug = 1;
my $ajax_general_debug = 1;
$pjx->JSDEBUG($ajax_javascript_debug);
$pjx->DEBUG($ajax_general_debug);

# this outputs the html for the page.

print $pjx->build_html($q,\&main,""); # The extra "" keeps Ajax.pm from causing "Use of uninitialized value" warnings.

sub main {
    my $html = "";
    $html .= $q->start_html(-title=>$lang{'title'},
			    -script=>[{-language=>'JAVASCRIPT', -src=>$settings{'tabber js filename URL'}},     # creates the navigation tabs on the left
				      {-language=>'JAVASCRIPT', -src=>$settings{'boxover js filename URL'}},    # creates the tooltip items on tab labels
				      {-language=>'JAVASCRIPT',
				       -code=>"var tabberOptions= {'manualStartup':true}"}],
			    -style=>{-src=>'/css/example.css',
				     -code=>'.tabber{display:none}'}
			    ) . "\n";

    $html .= &draw_AJAX_navigation("0main&images");

    # begin search sidebar
    $html .= "\n" . "<table width='100%' border='1' resize='true'><tr><td width='20%'>\n";
    $html .= "\n" . $q->start_div({-class=>"tabber", -id=>"sidebartabs", -style=>"border:1px solid blue; width: 100%; height: 100%"}) . "\n";

    $html .= &sidebar_content;
    $html .= $q->end_div . $q->comment("ends (class=\"tabber\" id=\"sidebartabs\")") . "\n";
    # end search sidebar
    $html .= "\n" . "</td> <td width='80%'>\n";

    # begin main bar?
    $html .= "\n" . $q->start_div({-id=>"mainbar", -style=>"border:1px solid green; width: 100%; height: 100%"}) . "\n";
    $html .= "hello";
    $html .= $q->end_div . $q->comment("ends (id=\"mainbar\")") . "\n";

    $html .= "\n" . "</td></tr></table>\n";

    $html .= &allowAjaxSource;
    $html .= <<END_script;
<script type="text/javascript">

/* Since we specified manualStartup=true, tabber will not run after
   the onload event. Instead we run it now, to prevent any delay
   while images load.
*/

tabberAutomatic(tabberOptions);

</script>
END_script

    $html .= $q->end_html;
    return $html;
}

sub sidebar_content {
    my $html;
    $html .= $q->p("date") if (0);
    $html .= $q->p("events") if ($system_status{'use okay'} && $system_status{'search events'});
    $html .= $q->p("locations") if ($system_status{'use okay'} && $system_status{'search locations'});
    $html .= $q->p("tags") if ($system_status{'use okay'} && $system_status{'search tags'});
    $html .= $q->p("random") if ($system_status{'use okay'});
	$html .= &sidebar_admin_login  unless (&isAdmin);
#    $html .= $q->p("The next step is to allow admin to logon.") unless (&isAdmin);
	$html .= &sidebar_search_tab('tag');    # added just for filler while trying to get admin login to not require entire screen refresh
#	$html .= &sidebar_search_tab('event')  if (&isAdmin);  # added just for filler while trying to get admin login to not require entire screen refresh
#    $html .= $q->p("Need to allow the admin to logoff") if (&isAdmin);
#    $html .= $q->p("Then we need to allow admin to create images tables.") if (&isAdmin);
#    $html .= $q->p("Status") if ($system_status{'use okay'} && &isAdmin);

#
#	$html .= &sidebar_search_tab('location');
#	$html .= &sidebar_event_tab;

    return $html;
}


sub sidebar_search_tab {
    my ($tabtype) = shift;
    my $html;

    warn ("in sidebar $tabtype");
    # Use -title=>"header=[hoverbox title] body=[hoverbox body]" to get a hoverbox.  use <h2> tag to label the tab
    $html .= "\n" . $q->start_div({-class=>"tabbertab", -id=>$tabtype . "searchtab", 
				   -style=>"border: 1px solid black; width: 100px; height: 480px; overflow: none", # THESE VALS NOT CAREFULLY CHOSEN
				   -title=>"header=[$lang{$tabtype . ' tab hover title'}] body=[$lang{$tabtype . ' tab hover body'}]"}) . "\n";
    $html .= "\n" . $q->h2($lang{$tabtype . ' tab'}) . "\n";

    $html .= "\n" . $q->start_form;
    $html .= "\n" . $q->textfield({-name=>$tabtype, -id=>$tabtype . "field", -onkeyup=>$tabtype . "_search( ['" . $tabtype . "field'], ['rdiv$tabtype'] ); return true;"}). "\n"; 
    $html .= $q->end_form. "\n";
    $html .= "\n" . $q->start_div({-id=>"rdiv$tabtype", 
				   -style=>"border: 1px solid black; width: 80px; height: 460px; overflow: auto"}  # THESE VALS NOT CAREFULLY CHOSEN
				  );
    $html .= $q->end_div . $q->comment("ends (id=\"rdiv$tabtype\")") . "\n";

    $html .= "\n" . $q->end_div . $q->comment("ends (class=\"tabbertab\" id=\"" . $tabtype . "searchtab\")") . "\n";

    return $html;
} # end sidebar_search_tab

# Draw the admin login form
sub sidebar_admin_login {
    my $html;
    # Use -title=>"header=[hoverbox title] body=[hoverbox body]" to get a hoverbox.  use <h2> tag to label the tab
    $html .= "\n" . $q->start_div({-class=>"tabbertab", -id=>"admin_logintab", 
				   -style=>"border: 1px solid red; width: 100px; height: 480px; overflow: none", # THESE VALS NOT CAREFULLY CHOSEN
				   -title=>"header=[$lang{'admin login tab hover title'}] body=[$lang{'admin login tab hover body'}]"}) . "\n";
    $html .= "\n" . $q->h2($lang{'admin login tab'}) . "\n";


    $html .= "\n" . $q->p($lang{'enter admin password'}) . "\n";


    $html .= "\n" . $q->start_form;
    $html .= "\n" . $q->textfield({-name=>$settings{'name of admin pw field'}, 
				   -size=>"10", -maxlength=>"15", 
				   -id=>"adminlogin",
				   -onBlur=>"admin_login( ['adminlogin'], ['rdiv2'] ); sidebar_content( ['adminlogin'], ['sidebartabs']); setTimeout(\"tabberAutomatic(tabberOptions);\",2000); return true;"}). "\n"; 

    $html .= $q->end_form. "\n";
    $html .= "\n" . $q->start_div({-id=>"rdiv2", 
				   -style=>"border: 1px solid black; width: 80px; height: 460px; overflow: auto"}  # THESE VALS NOT CAREFULLY CHOSEN
				  );
    $html .= $q->end_div . $q->comment("ends (id=\"rdiv\")") . "\n";

    $html .= "\n" . $q->end_div . $q->comment("ends (class=\"tabbertab\" id=\"admin_logintab\")") . "\n";

    return $html;
} # end sidebar_search_tab

sub tag_search {
    my ($tag) = @_;
    my $html = "";

    warn ("in tag_search");
    # set up DB connection
    unless ($dbh = &DBConnect(%dbHash)) {
	$html .= $q->p($lang{'cannot reach db'});
	return $html;
    }
    $sql = qq< select * from tags where tag_sortname like ? or tag_displayname like ? order by tag_sortname>;
    $sth = $dbh->prepare( $sql );
    $sth->execute( $tag . '%', $tag . '%');

    if ($sth->rows()) {
	my @items;
	while ( my $row = $sth->fetch() ) {
#	    warn ("images::tag_search found $tag");
	    push (@items, $row->[2]);
	}
	my $list_length = $settings{'max search list length'} || 25;
	$list_length = (2+$#items) if ((2+$#items) < $list_length);
	$html .= $q-> scrolling_list(-name=>'tag_matches',
				     -id=>'tag_matches',
				     -onChange=>"main_fart(['tag_matches'], ['mainbar'] ); return true;",
				     -values=>\@items,
				     -default=>$items[0],
				     -size=>$list_length,
				     -multiple=>"true");
    } else {
	$html .= $lang{"no tag starts with"} . " " . $tag;
    }
    # disconnect from the database causes $html not to be returned
    # &DBDisconnect();

    return $html;
}

sub main_fart {
    my @values = @_; # $q->param('tag_matches');
    my $html = $q->p(join (", ", @values));
    return $html;
}


 sub sidebar_event_tab {
     my $html;
     # Use -title=>"header=[hoverbox title] body=[hoverbox body]" to get a hoverbox.  use <h2> tag to label the tab
     $html .= "\n" . $q->start_div({-class=>"tabbertab", -id=>"eventsearchtab", 
 				   -title=>"header=[$lang{'event tab hover title'}] body=[$lang{'event tab hover body'}]"}) . "\n";
     $html .= "\n" . $q->h2($lang{'event tab'}) . "\n";
 
     $html .= $q->p("spam");  # we need to learn how to hide and display things.  right now the tag search field is hardcoded onto the front page.  That shit ain't going to work.  Need to have a hideable sidebar with various content in it.  Hideable is optional, but gotta allow tags / cal / event / random to be browsed/searched");
 
     $html .= "\n" . $q->end_div . $q->comment("ends (class=\"tabbertab\" id=\"eventsearchtab\")") . "\n";
     return $html;
 } # end sidebar_event_tab


sub location_search {
    &tag_search(@_);
}

sub event_search {
    &tag_search(@_);
}

# Image::Magick vars
my ($img, $imageData, $thumbData, $err);


#!     $file{'image'} = $filename;
#!     $file{'data'} = $binary_image_data;

#! use this I::M and DBI code     # convert image to thumbnail
#! use this I::M and DBI code     $img = new Image::Magick;
#! use this I::M and DBI code     $err = $img->Read($file{'image'});
#! use this I::M and DBI code     die "Can't read image file: $err\n" if $err;
#! use this I::M and DBI code     $imageData = $img->ImageToBlob();
#! use this I::M and DBI code     $err = $img->Scale(geometry=>"200x200");
#! use this I::M and DBI code     die "Can not scale image file: $err" if $err;
#! use this I::M and DBI code     $thumbData = $img->ImageToBlob();
#! use this I::M and DBI code     
#! use this I::M and DBI code     # build, prepare and execute SQL command
#! use this I::M and DBI code     $sql = "REPLACE INTO Gallery 
#! use this I::M and DBI code       (Date, Image, Thumb, Type, Title, 
#! use this I::M and DBI code       Comments, Category)
#! use this I::M and DBI code       VALUES (NOW(), ?, ?, ?, ?, ?, ?)";
#! use this I::M and DBI code     $sth = $dbh->prepare($sql)
#! use this I::M and DBI code       or DBError("Died in prepare");
#! use this I::M and DBI code     $sth->execute($imageData, $thumbData, 
#! use this I::M and DBI code       $content_type, $title, $comments, 
#! use this I::M and DBI code       $category)
#! use this I::M and DBI code       or DBError("Died in execute");
#! use this I::M and DBI code 
#! use this I::M and DBI code     # get the last inserted ID to build a URL
#! use this I::M and DBI code     $sql = "SELECT ID FROM Gallery 
#! use this I::M and DBI code       WHERE ID=LAST_INSERT_ID()";
#! use this I::M and DBI code     $sth = $dbh->prepare($sql)
#! use this I::M and DBI code       or DBError("Died in prepare");
#! use this I::M and DBI code     $sth->execute()
#! use this I::M and DBI code       or DBError("Died in execute");
#! use this I::M and DBI code     $dbData = $sth->fetchrow_hashref();
#! use this I::M and DBI code     $sth->finish();
#! use this I::M and DBI code     $id = $dbData->{'ID'};
#! use this I::M and DBI code 

#======############################################################################################################
#======##
#======##  If we can reach the database, then check for images and search attribute tables.
#======##  &check_tables_in_db
#======##  
#======##    Are there tables in the database?             (N -> allow admin login and start creating tables)
#======##    Are there attribute tables for search?        (N -> allow admin login to create the tables)
#======##
#======## not yet checked:   Are there pictures in the images table?       (N -> allow admin login and import images)
#======##
#======##  First, compare tables that exist to tables that are needed
#======##
#======##  The search attribute tables are desireable, but not necessary for
#======##  use.  So, if they don't exist, the system will still work for
#======##  users, but just with limited functionality.  This is controlled by
#======##  %system_status hash.  "TABLENAME exists" and "search TABLENAME"
#======##  exist in the hash for required and desireable tables,
#======##  respectively.
#======##
#======############################################################################################################
#======
#======sub check_tables_in_db {
#======    
#======    my @row;
#======    my %table_exists;
#======    my @have_useful_table;
#======
#======    $sth = $dbh->prepare("show table status;"); 
#======    $sth->execute;
#======
#======    # keep track of tables that exist
#======    while (@row = $sth->fetchrow_array) {
#======	my $tablename = $row[0];
#======	my $numrows = $row[4];
#======	warn ($tablename . ":" . $numrows);
#======	$table_exists{$tablename} = 1 if ($numrows > 0);
#======    }
#======	
#======
#======    # compare existing tables (%table_exists) to list of required tables ($settings{'required tables'})
#======    foreach my $needed_table (split " ", $settings{'required tables'}) {
#======	if ($table_exists{$needed_table}) {
#======	    #  This will determine what tabs will be available in the main menu.
#======	    $system_status{$needed_table . ' exists'} = 1;
#======	} 
#======	else
#======	{
#======	    push (@need_tables, $needed_table);
#======	}
#======    }
#======
#======    # compare existing tables (%table_exists) to list of usesful tables ($settings{'useful tables'})
#======    foreach my $wanted_table (split " ", $settings{'useful tables'}) {
#======	if ($table_exists{$wanted_table}) {
#======	    #  specify that it's okay to use the table.  This information
#======	    #  will determine what tabs will be available in the main menu.
#======	    $system_status{'search ' . $wanted_table} = 1;
#======	} 
#======	else
#======	{
#======	    push (@want_tables, $wanted_table);
#======	}
#======    }
#======
#======    if ($#need_tables == -1) {
#======	$system_status{'use okay'} = 1;  # the system can be used, at least a little bit.
#======    }
#======    else
#======    {
#======	# We need some tables before we can use the system.  Check to see if admin can log in.
#======
#======	if (&admin_password_exists) {
#======	    $system_status{'is admin'} = &isAdmin;
#======#	    throw Must_make_tables;
#======	}
#======	else {
#======	    # We can't continue without the admin, but there's no password for the admin!
#======	    die with Critical_error(-text=>$lang{'admin disabled'});
#======	}
#======    }
#======}
#======
#======sub admin_password_exists {
#======   return mkdef($settings{'content admin password'}) ? 1 : 0;
#======}

############################################################################################################
##
##  &critical_settings_check is supposed to make sure the system is fit for use whatsoever.
##
##  Basically:
##    We must be able to read the settings files into hashes
##    tabber.js and boxover.js are required
##    We must be able to access the database
##
##  If NO to any of the above, it's a critical failure from which this program cannot recover.
##    
##  But, try to fail gracefully; errors here will most likely fail during initial setup, 
##  so the user (admin) should be given an idea of which file didn't exist or had a problem, etc..
##
##  &hash_read and &DBConnect will throw errors if they fail.
##    
############################################################################################################
sub critical_settings_check {

    # this is the root of all settings in the images project
    &hash_read(\%settings,$settings_file);

    # this allows the user interface to be in different languages
    unless ($settings{'language file'}) {
	die with Critical_error(-text=>"No 'language file' entry in $settings_file.  It should point to a file with text output lines in your preferred language.");
    }
    &hash_read(\%lang,$settings{'language file'});

    # info on how to connect to the database
    unless ($settings{'dbHash file'}) {
	my $err_txt = $lang{'no dbHash file'} || "No 'dbHash file' entry in $settings_file.  It should point to a file with mySQL connection settings.";
	die with Critical_error(-text=>$err_txt);
    }
    &hash_read(\%dbHash,$settings{'dbHash file'});

    unless (-f $settings{'URL file base'} . $settings{'tabber js filename URL'}) {
	my $err_txt = $lang{'no tabber.js file'} || "No 'tabber js filename URL' entry in $settings_file.  It should point to publicly available tabber.js";
	die with Critical_error(-text=>$err_txt);
    }

    unless (-f $settings{'URL file base'} . $settings{'boxover js filename URL'}) {
	my $err_txt = $lang{'no boxover.js file'} || "No 'boxover js filename URL' entry in $settings_file.  It should point to publicly available boxover.js";
	die with Critical_error(-text=>$err_txt);
    }

    # Make sure we can get to the database.
    $dbh = &DBConnect(%dbHash);
}  # &critical_settings_check

sub checkAdminPassword {
    my %write_cookies;
    my ($images_admin_password) = @_;

    $write_cookies{$settings{'name of admin pw field'}} = $images_admin_password;
    &setCookies(%write_cookies);

    if ($images_admin_password eq $settings{'content admin password'}) {
	$system_status{'is admin'} = 1;
	return $q->p($lang{'correct admin password'});
    }
    else
    {
	$system_status{'is admin'} = 0;
	return $q->p($lang{'invalid admin password'});
    }
}

sub isAdmin {
    my %read_cookies = fetch CGI::Cookie;
    my %write_cookies;
    my $images_admin_password;

    if ($images_admin_password = $q->param($settings{'name of admin pw field'})) {
	$write_cookies{$settings{'name of admin pw field'}} = $images_admin_password;
	&setCookies(%write_cookies);
    }
    elsif ($read_cookies{$settings{'name of admin pw field'}}) {
	$images_admin_password = $read_cookies{$settings{'name of admin pw field'}}->value;
    }

    if ($images_admin_password eq $settings{'content admin password'}) {
	return 1;
    }
    # else
    0;    # somehow this seems more dramatically false.
}

######################################################
##
##  We have come to a problem that cannot be resolved by this script.
##  Exit and display hopefully useful information.
##
######################################################
sub critical_error_handler {
    my $err = shift;

    print "Content-type: text/html\n\n";  # This shouldn't be needed, but breaks otherwise
    print $q->start_html($lang{'title'});
    print $q->p("Sorry.. ", $err->{"-text"});
    print $q->p("This is a critical error from which I cannot recover.");
    print $q->end_html;

    warn ("A critical error occured: ", $err->{"-text"});
    exit;
}


######################################################
##
##  We have come to a problem that can be resolved by the
##  administrator.  But we didn't find a param or cookie with
##  (correct) administrator password, so ask for it.
##
######################################################
#sub ask_for_admin_password {
#    print "Content-type: text/html\n\n";  # This shouldn't be needed, but breaks otherwise
#    print $q->start_html($lang{'title'});
#    print $q->p($lang{'recoverable oops'});
#    print $q->p($lang{'enter admin password'});
#    print $q->start_form;
#    print $q->textfield(-name=>$settings{'name of admin pw field'},-size=>20,-maxlength=>20), "\n";
#    print $q->end_form;
#    print $q->end_html;
#    exit;
#}

##   
##      mySQL code used to create tables:
##   
#######################################################################################################################
##   
##   CREATE TABLE `tags` (
##     `tagID` INT( 6 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY ,
##     `tag_sortname` VARCHAR( 20 ) NOT NULL ,
##     `tag_displayname` VARCHAR( 25 ) NOT NULL ,
##   INDEX ( `tag_sortname` ) ,
##   UNIQUE ( `tag_displayname` )) TYPE = MYISAM COMMENT = 'tags created with phpMyAdmin 13 June 2006';
##   
#######################################################################################################################
##   
##    CREATE TABLE `images` (
##   `imageID` INT( 6 ) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY ,
##   `imageDate` DATETIME NULL ,
##   `fileDate` DATETIME NULL ,
##   `title` VARCHAR( 50 ) NOT NULL ,
##   `comment` BLOB NULL ,
##   `path` VARCHAR( 100 ) NOT NULL ,
##   INDEX ( `imageDate` , `fileDate` )) TYPE = MYISAM ;
##
##  
##  $sql = 'CREATE TABLE `images` ('
##          . ' `imageID` INT(6) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, '
##          . ' `imageDate` DATETIME NULL, '
##          . ' `fileDate` DATETIME NULL, '
##          . ' `title` VARCHAR(50) NOT NULL, '
##          . ' `comment` BLOB NULL, '
##          . ' `path` VARCHAR(100) NOT NULL,'
##          . ' INDEX (`imageDate`, `fileDate`)'
##          . ' )'
##      . ' TYPE = myisam;';
##  
#######################################################################################################################
##  
##  $sql = 'CREATE TABLE `image_sizes` ('
##          . ' `imageSizeID` INT(6) UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY, '
##          . ' `imageID` INT(6) UNSIGNED NOT NULL, '
##          . ' `w` INT(5) UNSIGNED NOT NULL, '
##          . ' `h` INT(5) UNSIGNED NOT NULL, '
##          . ' `name` VARCHAR(100) NOT NULL,'
##          . ' INDEX (`imageID`)'
##          . ' )'
##      . ' TYPE = myisam;';
##  
#######################################################################################################################
