#!/usr/bin/perl -w

######################################################################
#
# rob_updates.pl sends one email per address to a mySQL list of emails
#
# v 0.5 read db login info from a file
#
# It allows users to opt-out with two clicks.  It doesn't
# keep track of bounces.  It doesn't allow opt-ins (thereby
# sidestepping the issue of forged emails, etc).  It archives the
# emails on my site.
#
# Author: Rob Nugen
# Latest version available at http://robnugen.com/cgi-bin/source_viewer.pl?file=rob_updates.pl
# or http://robnugen.com/wiki/index.php?title=Rob_updates.pl
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
######################################################################

#-------------------------------------------------------------
#- 
#-   the basic idea I have in my brain here is to allow automation of cleansing the list.
#- 
#-   adding three date fields to the database:
#-      added            : the date the record was added
#-      removed          : the date the record was dropped
#-      keep_through     : the minimum date before asking if they should be removed
#- 
#-   adding a status field with three possible values:
#-     [green | yellow | red]
#- 
#-   From now on, I will not actualy remove names from the list.  The code will check their status to see if they get an email or not.
#- 
#-   For each record:
#-      When adding a new record: update 'added' field
#-   
#-      When sending an email:
#-         If red, do not send.
#-         If yellow, change to red, update 'removed' field, and do not send.
#-         If green, check keep_through.
#-            If today > keep_through
#-               change to yellow
#-               tag the message (let me know if you wanna stay on the list)
#-               send the message
#-            else
#-               send the message
#-         end if green
#- 
#-      When doing any other processing, if remove is requested, change to red, update 'removed' field
#- 
#-   When I get a request for extension, I manually boost their keep_through date.
#- 
#-   This system is contingent on the cycle of emails being sent being
#-   less than the expected cycle that users will check their email
#-   and respond to a query if they want to extend.  If I send out too
#-   quickly, they will not have time to respond.
#- 
#-   Because I check my email more often than the average bear, I will
#-   allow an easy mechanism for me to change their status, in case
#-   they went red and wanna come back.
#- 
#-   I want to write some nice AJAX style tags to edit the fields on the View Names screen
#- 
#-------------------------------------------------------------

require "allowSource.pl";
require "setCookies.pl";
require "mkdef.pl";
require "displayFile.pl";
require "draw_navigation.pl";
require "DB_CDE.pl";  #  DBI code from Mike Schienle
require "hash_io.pl";

my $q = new CGI;      # will be used for params, cookies, Ajax, html output

use lib "/home/barefoot_rob/lib/perl5/site_perl";  # to use modules installed in my user space (in this case Ajax and Error)
use strict;
use CGI qw(:all fatalsToBrowser);
use CGI::Cookie;
use DBI;
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

my ($env_var,$next_action,$pass,%write_cookies,%read_cookies);

# general settings for images, output language, and db access are stored in text files that will be read into hashes, starting with %settings
my ($settings_file,%settings,%lang,%dbHash);
$settings_file = "/home/barefoot_rob/settings/rob_updates.settings";
my $nav_settings_file = "/home/barefoot_rob/settings/navigation.settings";  # this semi-hack allows one definition of location of navigation_definitions.txt

# DBI handles
my ($sth, $sql, $rv, $dbh, $dbData);

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

my $from_address = "rob\@robnugen.com";
my $default_action = "add names";

my $query = new CGI;

if (mkdef($query->param('do')) eq 'remove') {
    &do_remove;
    die ("rob_updates.pl::do_remove returned to main level, and was killed at that point.  This is bad.  See rob_updates for deets.");
}

unless(&isAdmin) {
    # password does not work for mySQL database
    print $query->header, $query->start_html("Rob Updates");

    print "\n", $query->p( $query->start_form, "\n",
		     "password:", $query->password_field(-name=>$settings{'name of admin pw field'}), "\n",
		     $query->end_form), "\n";

    print $query->end_html;
} else {
    # password is confirmed good

    print $query->header, $query->start_html("Rob Updates");

    &do_pre_processing;   # these are users' requests to opt out, or admin changing people's status

    &draw_navigation("0main&none");

    if (-d "$settings{'public_html_dir'}$settings{'update_directory'}") {
	print "\n", $query->p( "Using $settings{'public_html_dir'}$settings{'update_directory'}" ), "\n";
    } 
    else {
	print "\n", $query->p( "<font color='red'>$settings{'public_html_dir'}$settings{'update_directory'} IS NOT A DIRECTORY</font>" ), "\n";
    } 

    print "\n", $query->p( "Main Menu", $query->start_form(-name=>'form1'),
		     $query->submit(-name=>'do', -value=>'compose'), "\n",
		     $query->submit(-name=>'do', -value=>'create list'), "\n",
		     $query->submit(-name=>'do', -value=>'delete list'), "\n",
		     $query->submit(-name=>'do', -value=>'add names'), "\n",
		     $query->submit(-name=>'do', -value=>'view names'), "\n",
		     $query->submit(-name=>'do', -value=>'logout'), "\n",
		     $query->end_form), "\n";

    # If there is not already a value of $next_action, get the param, else get default
    unless ($next_action) {
	$next_action = $query->param('do') || "$default_action";
    }


    if ($next_action eq "add names") {
	&draw_add_names;
    } elsif ($next_action eq "submit names") {
	&submit_names;
    } elsif ($next_action eq "logout") {
	&logout;
    } elsif ($next_action eq "create list") {
	&draw_create_list;
    } elsif ($next_action eq "create this list") {
	&create_this_list;
    } elsif ($next_action eq "delete list") {
	&draw_delete_list;
    } elsif ($next_action eq "delete this list") {
	&delete_this_list;
    } elsif ($next_action eq "compose") {
	&draw_send_email;
    } elsif ($next_action eq "view names") {
	&draw_view_names;
    } elsif ($next_action =~ m/sort/m) {
	&view_names;
    } elsif ($next_action eq "send emails") {
	&draw_blog_option;
	&send_emails unless $query->param('no_emails');
	&write_email_to_disk unless $query->param('no_archive');
    } else {
	print "\n", $query->p("We don't know how to $next_action");
    }

    &allowSource;

    print $query->end_html;
}

sub do_remove {

    # ANY USER can run this function with ?do=remove.  They don't need
    # a password to get into this code.  This function must exit() or
    # die() at the end.

    # this function keeps track of requests to be removed from my mass
    # email lists.  Users don't have my mySQL password, so this writes
    # the requests to a flatfile which is read and processed by
    # rob_updates.pl before any other processing is done.
    
    my ($id,$cksum,$list_name,$confirmed);
    
    $id = mkdef($query->param('id'));
    $cksum = mkdef($query->param('ck'));
    $list_name = mkdef($query->param('l'));
    $confirmed = mkdef($query->param('sure'));
    
    print $query->header, $query->start_html("opt-out of Rob Updates");
    
    unless ($id && $cksum && $list_name) {
    
        # $id, $cksum, $list_name must be defined.  
        # This will be executed if some mucked up params are sent to
        # remove.pl (by hand, most likely)
        print $query->p("There was a problem.  Please send me an email at <a href='mailto:rob\@robnugen.com'>rob\@robnugen.com</a> to be removed.");
        &notify_rob("This link didn't work at all: http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}");
    
    } elsif (-f $settings{'semaphore_filename'}) {
        # The semaphore file exists; someone else clicked at the same
        # time.  This user could probably click again and be fine, but an
        # email is being sent so I can click for them.
        print $query->p("You'll be off the list soon.");
        &notify_rob("Server was busy (semaphore existed) click again: http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}");
    } elsif ($confirmed eq "") {
        my $URL = "http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}&sure=yes";
        print $query->p("Confirm:");
        print $query->p("Click ", $query->a({-href=>$URL}, "here"), " to be removed from $list_name\n");
    } else {
        # All is good; create the semaphore file
        open(SEMAPHORE, ">$settings{'semaphore_filename'}");
        print SEMAPHORE "removing $id $cksum from $list_name";
        close(SEMAPHORE);
    
        # update the opt-out file
        open(OUT, ">>$settings{'opt_out_q_filename'}");
        print OUT join (":",('remove',$id,$cksum,"$list_name")), "\n";
        close(OUT);
        print $query->p("You have been removed from the list.");
    
        # remove the semaphore file
        unlink ("$settings{'semaphore_filename'}");  # the next process can do its thing
    }

    &allowSource;
    print $query->end_html;
    exit;   # no error; all checking was done above.

}

sub view_names {
    my $list_name = $query->param('list_name');

    unless (mkdef($list_name)) {
	print "\n", $query->p ( "Choose a list." );
    } else {
	my $order = $query->param('do');

	# Create ORDER BY clause according to the value of the button pressed
	if ($order =~ m/(by .*)/m) {
	    $order = "order $1";
	} else {
	    $order = "";
	}
	my $select_query = qq{SELECT * FROM $list_name $order};

	my $sth = $dbh->prepare ( $select_query );
	$sth->execute;
	my $count_emails = $sth->rows();
	my $all_email_addresses = $sth->fetchall_arrayref();

	# these are just names in the order returned by the DB, but not in the order of display, so it's confusing; sorry.
	my @field_names = qw(NAME EMAIL_ADDRESS ID CKSUM ADDED_DATE No_worries BYE/OK_TIL LANGUAGE STAT.);
	unshift (@$all_email_addresses, \@field_names);

	$sth->finish();
	$dbh->disconnect;

	unless ($count_emails) {
	    print "\n", $query->p ("Sorry; there are no email addresses in <b>$list_name</b>." );
	} else {
	    my $URL;

	    # This hidden form allows the admin (me) to edit various
	    # shnizzle about individual records.  Basically the
	    # individual's info is filled in with Javascript and then
	    # the form is submitted.
=pod   for debugging, use these fields, which should match the hidden fields below
				  $query->textfield(-name=>"id"), "\n",
				  $query->textfield(-name=>"ck"), "\n",
				  $query->textfield(-name=>"l", -value=>"$list_name"), "\n",
				  $query->textfield(-name=>"list_name", -value=>"$list_name"), "\n",
				  $query->textfield(-name=>"do", -value=>"$query->param('do')"), "\n",  # what to do after the admin do (ado)
				  $query->textfield(-name=>"years"), "\n",
				  $query->textfield(-name=>"ado"), "\n",
=cut

	    print "\n", $query->p($query->start_form(-name=>"admin_form"),
				  $query->hidden(-name=>"id"), "\n",
				  $query->hidden(-name=>"ck"), "\n",
				  $query->hidden(-name=>"l", -value=>"$list_name"), "\n",
				  $query->hidden(-name=>"list_name", -value=>"$list_name"), "\n",
				  $query->hidden(-name=>"do", -value=>"$query->param('do')"), "\n",  # what to do after the admin do (ado)
				  $query->hidden(-name=>"years"), "\n",
				  $query->hidden(-name=>"ado"), "\n",
				  $query->end_form), "\n";

	    print "\n", $query->p("Names in $list_name, $order"), "\n";
	    print "\n<pre>\n";
	    my ($nameLen, $emailLen) = (30,40);  # weak workaround to guesstimate how wide the fields should be
	    foreach my $person (@$all_email_addresses) {
		my ($name, $email, $id, $cksum, $added, $keep_through, $removed, $language, $status) = @$person;

		$language = "        " unless ($language);
		$nameLen = length($name) if length($name) > $nameLen;
	        $emailLen = length($email) if length($email) > $emailLen;


		unless ($status eq "STAT.")  		# skip printing the remove / extend buttons for the header
		{
		    # this code would be way cooler if it made some edit fields pop up via AJAX, but it was too tricky to do so I didn't
		    print $query->button(-value=>"e", -onClick=>"admin_form.id.value='$id'; admin_form.ck.value='$cksum'; admin_form.ado.value='edit'; admin_form.submit();"), " ";
		}
		else 
		{
		    print "     ";
		}

		my $removed_or_until_date = ($removed =~ m/0000/m) ? "$keep_through" : "$removed";  # if $removed is null, then show $added date
		printf ("%-" . $nameLen . "s %-" . $emailLen . "s ", $name, '&lt;' . "$email>");
		print "$language $added <font color='$status'>";
		printf ("%-6s",$status);
		print "</font> $removed_or_until_date ";

		# skip printing the remove / extend buttons for the header
		if ($status eq "STAT.") {
		    print "\n";
		    next;
		}

		if ($status eq 'green') {
		    # allow us to remove the recipient
		    print $query->button(-value=>"X", -onClick=>"admin_form.id.value='$id'; admin_form.ck.value='$cksum'; admin_form.ado.value='remove'; admin_form.submit();"), "";
		    foreach my $years (1, 2, 5, 10, 100) {
			print $query->button(-value=>"$years", -onClick=>"admin_form.id.value='$id'; admin_form.ck.value='$cksum'; admin_form.ado.value='restore'; admin_form.years.value='$years'; admin_form.submit();");
		    }
		    print "\n";
		}
		else
		{
		    # allow us to restore the recipient
		    foreach my $years (1, 2, 5, 10, 100) {
			print $query->button(-value=>"$years", -onClick=>"admin_form.id.value='$id'; admin_form.ck.value='$cksum'; admin_form.ado.value='restore'; admin_form.years.value='$years'; admin_form.submit();");
		    }
		    print "\n";

		}
	    }
	    print "</pre>\n";
	}
    }
}

sub do_pre_processing {
    &process_batch_changes;  # users' requests to opt-out
    &process_admin_changes;  # admin updating users
}

sub process_admin_changes {
    my $action = $query->param('ado');

    return unless $action;

    if ($action eq "restore") {
	&restore;
    }
    elsif ($action eq "remove") {
	&remove;
    }
    elsif ($action eq "edit") {
	&draw_edit_form;
    }
    elsif ($action eq "save changes") {
	&save_changes;
    } else {
	print "\n", $query->p("We can't make much ado about $action"), "\n";
    }

#    $next_action = $query->param('do');
}

sub save_changes {
    my $sth;

    my $name  = $query->param('name');
    my $email = $query->param('email');
    my $id    = $query->param('id');
    my $cksum = $query->param('ck');
    my $list  = $query->param('list_name');

    $sth = $dbh->prepare("UPDATE $list SET name=?, email=? WHERE id = ? AND cksum = ?");
    $sth->execute($name,$email,$id,$cksum);
    my $affected_rows = $sth->rows(); 

    $sth->finish();
    $dbh->disconnect;

}

sub draw_edit_form {

	my $select_query = "SELECT * FROM " . $query->param('list_name') . " where id=? and cksum=?";

	my $sth = $dbh->prepare ( $select_query );
	$sth->execute($query->param('id'), $query->param('ck'));
	my $count_emails = $sth->rows();
	my $all_name_array = $sth->fetchall_arrayref();
	my ($one_name) = @$all_name_array;
	$sth->finish();
	$dbh->disconnect;

	my ($name, $email) = @$one_name;

=pod
				  $query->hidden(-name=>"id"), "\n",
				  $query->hidden(-name=>"ck"), "\n",
				  $query->hidden(-name=>"l", -value=>"$list_name"), "\n",
				  $query->hidden(-name=>"list_name", -value=>"$list_name"), "\n",
				  $query->hidden(-name=>"do", -value=>"$query->param('do')"), "\n",  # what to do after the admin do (ado)
				  $query->hidden(-name=>"years"), "\n",
				  $query->hidden(-name=>"ado"), "\n",
=cut
	    print "\n", $query->p($query->start_form(-name=>"edit_form"),
				  $query->textfield(-name=>"name", -value=>"$name"), "\n",
				  $query->textfield(-name=>"email", -value=>"$email"), "\n",
				  $query->hidden(-name=>"id"), "\n",
				  $query->hidden(-name=>"ck"), "\n",
				  $query->hidden(-name=>"l"), "\n",
				  $query->hidden(-name=>"list_name"), "\n",
				  $query->hidden(-name=>"do", -value=>"$query->param('do')"), "\n",  # what to do after the admin do (ado)
				  $query->hidden(-name=>"ado", -value=>"save changes"), "\n",
				  $query->button(-value=>"save changes", -onClick=>"ado.value='save changes'; submit();"), "\n",
				  $query->end_form), "\n";


}

sub restore {
    my $id = mkdef($query->param('id'));
    my $cksum = mkdef($query->param('ck'));
    my $list_name = mkdef($query->param('l'));
    my $years = mkdef($query->param('years'));
    push (my @batch_request, "add:$id:$cksum:$list_name:$years");
    &process_opt_outs(\@batch_request);
}

sub remove {
    my $id = mkdef($query->param('id'));
    my $cksum = mkdef($query->param('ck'));
    my $list_name = mkdef($query->param('l'));
    push (my @batch_request, "remove:$id:$cksum:$list_name");
    &process_opt_outs(\@batch_request);
}

sub process_batch_changes { 
    if (-f $settings{'opt_out_q_filename'}) {

	my ($err,@batch_requests);
	if ($err = &read_opt_out_queue(\@batch_requests)) {
	    print "\n", $query->p("$err"), "\n";
	    die "$err";
	}
	if ($err = &process_opt_outs(\@batch_requests)) {
	    print "\n", $query->p("$err"), "\n";
	    die "$err";
	}
    }
}

sub read_opt_out_queue {
    my ($batch_requests) = @_;

    if (-f $settings{'semaphore_filename'}) {
	print $query->p($query->b("Server busy; can't process opt_outs"));
    } else {
	open(SEMAPHORE, ">$settings{'semaphore_filename'}");
	print SEMAPHORE "processing opt_outs";
	close(SEMAPHORE);

	open (OPT_OUT,"$settings{'opt_out_q_filename'}");
	while (<OPT_OUT>) {
	    push (@$batch_requests, $_);
	}

	close (OPT_OUT);
	unlink ("$settings{'opt_out_q_filename'}");
	unlink ("$settings{'semaphore_filename'}");  # the next process can do its thing
    }
    return 0;
}

sub process_opt_outs {
    my ($batch_requests) = @_;

    my $sth;

    foreach (@$batch_requests) {
	my ($action,$id,$cksum,$list_name,$years) = split (/:/,$_);  # $years is used when restoring people from yellow or red status

	if ($action eq "remove") {
	    $sth = $dbh->prepare("UPDATE $list_name SET status='RED', keep_through='0000-00-00', removed=NOW(), who='user' WHERE id = ? AND cksum = ?");
	    $sth->execute($id,$cksum);
	    my $affected_rows = $sth->rows(); 
	} elsif ($action eq "add") {
	    $sth = $dbh->prepare("UPDATE $list_name SET status='GREEN', removed='0000-00-00', who=NULL, keep_through=ADDDATE(NOW(), INTERVAL ? YEAR) WHERE id = ? AND cksum = ?");
	    $sth->execute($years,$id,$cksum);
            my $affected_rows = $sth->rows(); 
	} else {
	    print "\n", $query->p("We don't know how to $action a name from $list_name (or any other list)."), "\n";
	}

	$sth = $dbh->prepare("SELECT name, id, cksum, keep_through, removed FROM $list_name WHERE id = ? AND cksum = ?");
	$sth->execute($id,$cksum);
	my $affected_row_count = $sth->rows(); 
	my $affected_names_array = $sth->fetchall_arrayref();

	unless ($affected_row_count == 1) {
	    print "\n", $query->p($query->b("PROBLEM"), " with updating $id, $cksum.  There were $affected_row_count records matching the criteria."), "\n";
	}
	else 
	{
	    foreach my $name (@$affected_names_array) {
		my ($name, undef, undef, $keep_until, $removed) = @$name;
		if ($removed =~ m/0000/m) {
		    print "\n", $query->p("$name will be kept till $keep_until"), "\n";
		}
		else 
		{
		    print "\n", $query->p("$name has been removed"), "\n";
		}
	    }
	}
    }

    $sth->finish();
    $dbh->disconnect;
    return 0;
}

sub write_email_to_disk {

    my $HOURS_FROM_CALI_TO_TOKYO = 16; # doesn't need to be exact

    my $subject = $query->param('subject');
    $subject =~ s/ /_/g;   # replace %20 with _

    my $message = &htmlify($query->param('message'));

    my $navigation_params = $settings{'update_directory'};  # For drawing navigation at the top of the page
    $navigation_params =~ s|/|\&|sg;   # convert path into URL parameters
    $navigation_params = $navigation_params . "&$subject";   # $subject has already had spaces replaced with underscores
			   
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time + $HOURS_FROM_CALI_TO_TOKYO*60*60);
    $mon = sprintf("%02d",$mon + 1);   # make it mm
    $mday = sprintf("%02d",$mday);     # make it dd
    $year = $year + 1900;
    my $date = "$year-$mon-$mday";

    ##########################################################################
    #
    # Think of this as a footnote in the middle of the page.
    #
    # Above, we have calculated everything we need to know for writing
    # the files.  Below, we will write the files.  This footnote
    # explains the filenames being used.  The basic idea is to write
    # the updates in two places: in my journal, and in my 'travel'
    # directory.  Indexing for the journal is done with its own mechanism,
    # so we don't need to worry about it.  The indexing for the rest
    # of my site has been done by hand (until now) by updating the
    # file /home/barefoot_rob/setup_journal/navigation_definitions.txt.
    # Keeping that updated fell to the wayside; I would send out Rob
    # Updates, but never update that file, nor even write these to the
    # appropriate directory.
    #
    # When users click on (or enter into the location bar)
    # domain/travel I want them to see the most recent travel entry
    # I've created for that directory.  I will use symlinks for those.
    #
    # In conclusion, I will write the file two times:
    # /home/barefoot_rob/temp.robnugen.com/journal/yyyy/mm/dd$subject.html     (JOURNAL)
    # /home/barefoot_rob/temp.robnugen.com/travel/peace_boat/49/yyyy-mm-dd_$subject.shtml  (UPDATE)
    #
    # and then symlinks at all subdirectories of $settings{'update_directory'}
    # /home/barefoot_rob/temp.robnugen.com/travel/peace_boat/49/index.shtml ---> UPDATE
    # /home/barefoot_rob/temp.robnugen.com/travel/peace_boat/index.shtml    ---> UPDATE
    # /home/barefoot_rob/temp.robnugen.com/travel/index.shtml               ---> UPDATE
    # 
    ##########################################################################

    my $filename = "$settings{'update_directory'}/$date" . "_$subject.shtml";   # this will be written in $navigation_definitions file for auto-indexing
    my $full_filename = "$settings{'public_html_dir'}$filename";
    open (UPDATE, ">$full_filename");
    # This line is interpreted into navigation on the top page.
    print UPDATE '<!--#include virtual="/cgi-bin/draw_navigation_for_static_pages.pl?0main' . $navigation_params . '" -->', "\n";
    print UPDATE "\n", $query->p($query->b($query->param('subject'))), "\n";
    print UPDATE "\n", $query->pre($message, "\n");
    close (UPDATE);

    # Now point symbolic links to index.shtml in all the
    # subdirectories of $settings{'update_directory'}
    my $copy_of_update_directory = $settings{'update_directory'};
    while ($copy_of_update_directory) {
	my $default_filename = "$settings{'public_html_dir'}$copy_of_update_directory/index.shtml";  #  this will be viewed when the user clicks on travel -> peace boat
	unlink $default_filename;
	symlink $full_filename,$default_filename;
	# yank off the end of $copy_of_update_directory
	@_ = split('/', $copy_of_update_directory);
	pop;
	$copy_of_update_directory = join ('/', @_);
    }

    my $journal_filename = "$settings{'public_html_dir'}/journal/$year/$mon/$mday$subject.html";
    open  JOURNAL, ">$journal_filename";
    print JOURNAL "\n", $query->p($query->b($query->param('subject'))), "\n";
    print JOURNAL "\n", $query->pre($message, "\n");
    close JOURNAL;
    chmod 0600, $journal_filename;

    # Now write the corresponding line to navigation_defintions.txt
    my @dir_array = split (/\//,$settings{'update_directory'});
    my $last_dir = pop(@dir_array);
    open (OUT, ">>$settings{'index_definition_file'}");
    print OUT "\n$last_dir  $subject  <b>$subject</b>  $subject  $filename";
    close (OUT);
}

sub draw_blog_option {
    print $query->p("\n", 
		    $query->a({href=>"/blog/wp-admin/post.php",target=>"_new"},"put this in yer blog"),
		    "\n");

    print $query->p("\n<h2>", 
		    $query->a({href=>"/cgi-bin/preformatted_journal_index_writer.pl",target=>"_new"},"CLICK HERE to make it visible!!!"),
		    "</h2>\n");
}

sub htmlify {
    my ($text) = @_;
    $text =~ s/\r//g;       # we don't need no stinking CRs

    $text = &line_wrap($text, 83);  # do this first so the longer html chars below will not artificially make lines too long

    # Convert some special characters to html equiv
    $text =~ s/\&/\&amp;/gs;
    $text =~ s/</\&lt;/gs;
    $text =~ s/>/\&gt;/gs;
    $text =~ s/"/\&#34;/gs;      # "   to close the doublequote cause it mucks up emacs colorization

    # normal links
    $text =~ s|\b(http:[/.,;:?&=+@#\-\w]+[/~;\-\w])([^/~;\-\w])|<a href="$1">$1</a>$2|gis;
    return $text;
}

sub send_emails {
    my $list_name = $query->param('list_name');
    my $count_emails;

    unless (mkdef($list_name)) {
	print "\n", $query->p ( "Choose a list." );
    } else {

	my ($sth, $affected_rows);
#-      When sending an email:
#-         If red, do not send.
#-         If green, check keep_through.
#-            If today > keep_through
#-               change to yellow
#-               tag the message (let me know if you wanna stay on the list)
#-               send the message
#-            else
#-               send the message
#-         end if green


        #  If yellow, change to red, update 'removed' field, and do not send.
	$affected_rows = $dbh->do("UPDATE $list_name SET status='RED', keep_through='0000-00-00', removed=NOW(), who='time' WHERE status='YELLOW'");

	print "\n", $query->p("Just removed $affected_rows names from the list"), "\n" unless ($affected_rows eq '0E0');

	#  If green, and we are past keep_through date, then change to yellow.
	$affected_rows = $dbh->do("UPDATE $list_name SET status='YELLOW' WHERE keep_through<NOW() AND status='GREEN'");

	print "\n", $query->p("Will send list-cleansing warnings to $affected_rows names."), "\n" unless ($affected_rows eq '0E0');

	# Usually we would just select *, but I've mucked up the order of the fields so language is before status.  If there is no
	# value for language, it messes up the array in send_individual_email.  (___, ___ ... ___) = @$person;
        # Debating between various solutions and chose this easy one..
	my $email_query = qq{SELECT name, email, id, cksum, status, language FROM $list_name WHERE status != 'RED'};
	$sth = $dbh->prepare ( $email_query );
	$sth->execute;
	my $count_emails = $sth->rows();
	my $all_email_addresses = $sth->fetchall_arrayref();

	$sth->finish();
	$dbh->disconnect;

	unless ($count_emails) {
	    print "\n", $query->p ("Sorry; there are no email addresses in <b>$list_name</b>." );
	} else {
	    print "\n", $query->p("Sending message to $list_name.");
	    foreach my $person (@$all_email_addresses) {
#		print $query->p(@$person);
		&send_individual_email($person,$list_name);
	    }
	    print "\n", $query->pre(line_wrap($query->param('message'),83));
	}
    }
}
	
sub send_individual_email {
    my ($person,$list_name) = @_;
    my ($name, $address, $id, $cksum, $status, $language) = @$person;

    my $subject = $query->param('subject');
    my $URL = "http://robnugen.com/cgi-bin/" . $settings{'remove_pl'} . "?do=remove&id=$id&ck=$cksum&l=$list_name";

    my $remove_text = "If you do not want any more Rob Updates, click $URL";

    if ($language eq 'Japanese') {
	$remove_text = "このメルをいらない人ここをクリックして下さい: $URL";  # kono email iranai hito koko o kurikku shite kudasai
    }

    if ($status eq 'green') {
	print $query->br ("Sending to $name &lt;$address>."), "\n";
    } elsif ($status eq 'yellow') {
	print $query->br($query->b("Last message warning sent to $name &lt;$address>.")), "\n";
    } else {
	print $query->br($query->h1("Status $status found, and we did not expect it!!")), "\n";
    }

    my $mail_prog = "/usr/sbin/sendmail"; # location of sendmail on server;

    open(MAIL,"|$mail_prog -t");
    print MAIL "To: $name <$address>\n";
    print MAIL "From: $from_address\n";
    if ($language eq 'Japanese') {
	print MAIL "Content-Type: text/plain; charset=\"EUC-JP\"\n";
    }
    print MAIL "Subject: $subject\n\n";
    print MAIL "$remove_text\n";
    if ($language eq 'Japanese') {
	print MAIL "(If you cannot read the Japanese above, please email me at rob\@robnugen.com.)\n\n";
    } else {
	print MAIL "\n";  # just to get the spacing right.  bad workaround, but I don't care!
    }

    if ($status eq 'yellow') {
	print MAIL "First, this is the last Rob Update you will receive.\n";
	print MAIL "If you do not want any more updates from me, simply Do Nothing.\n";
	print MAIL "With neither complaint nor apology, your address will be removed from\n";
	print MAIL "this list unless you request otherwise.\n";

	print MAIL "\nIf you think \"Rob wouldn't do that to me!\" I invite you to think again.\n";
	print MAIL "Because you are reading this, I have overlooked your name, erring toward\n";
	print MAIL "   *  Not Bothering People, and\n";
	print MAIL "   *  Not sending messages to abandoned addresses.\n";

	print MAIL "\nOn the good side, I have written the code so I can specify\n";
	print MAIL "per-individual how long they would like to stay on the list before\n";
	print MAIL "being asked, \"are you sure you want these updates??\"\n";
	print MAIL "The options are 1, 2, 5, 10, or 100 years.\n";

	print MAIL "\nIn short, I am cleansing my list;\n";
	print MAIL "this is the last Rob Update you will receive, unless you email me back!\n\n";
    }

    print MAIL $query->param('message');
    print MAIL "\n\n$remove_text";
    print MAIL "\n\n";
    close (MAIL);
}

sub get_list_info {
    my (@lists,%list_labels); # references to these will be returned and used in a form

    # find out what lists are available
    my $display_email_lists_query = qq{SELECT * FROM email_lists};

    my $sth = $dbh->prepare ( $display_email_lists_query );
    $sth->execute;
    my $count_lists = $sth->rows();
    my $all_email_lists = $sth->fetchall_arrayref();

    $sth->finish();

    if ($count_lists) {
	foreach my $list (@$all_email_lists) {
	    my ($list_name, $list_type) = @$list;
	    my $this_list_query = qq{SELECT * FROM $list_name WHERE status='green'};
	    
	    my $sth = $dbh->prepare ( $this_list_query );
	    $sth->execute;
	    my $count_addresses = $sth->rows();
	    $sth->finish();
	    
	    push (@lists,$list_name);
	    $list_labels{"$list_name"} = "$list_name ($count_addresses $list_type addresses)";
	}
	$dbh->disconnect;
	return (\@lists,\%list_labels);
    } else {
	return 0;   # no lists available
    }

}  # get_list_info

sub draw_view_names {
    my ($lists,$list_labels) = &get_list_info;

    unless ($lists) {
	print "\n", $query->p ("Sorry; there are no lists from which names can be removed.");
    } else {
	print "\n", $query->p("view names:", "\n", 
			      $query->start_form(-name=>'form1'), "\n",
			      $query->br($query->radio_group(-name=>'list_name', -values=>$lists, -linebreak=>'true', -labels=>$list_labels), "\n"),
			      $query->submit(-name=>'do', -value=>'no sort'), "\n",
			      $query->submit(-name=>'do', -value=>'sort by name'), "\n",
			      $query->submit(-name=>'do', -value=>'sort by email'), "\n",
			      $query->submit(-name=>'do', -value=>'sort by status'), "\n",
			      $query->submit(-name=>'do', -value=>'sort by keep_through'), "\n",
			      $query->submit(-name=>'do', -value=>'sort by language'), "\n",
			      $query->end_form), "\n";
    }
}

sub draw_send_email {
    my ($lists,$list_labels) = &get_list_info;

    unless ($lists) {
	print "\n", $query->p ("Sorry; there are no lists to which you can send an email.");
    } else {
	print "\n", $query->p( "Compose your message here:", "\n",
			       $query->start_form(-name=>'form1'), "\n",
			       $query->p("Subject:", $query->textfield(-name=>'subject'), "\n"),
			       $query->br,
			       $query->textarea(-name=>'message', -wrap=>'virtual',
						-rows=>25,
						-columns=>90), "\n",
			       $query->br($query->radio_group(-name=>'list_name', -values=>$lists, -linebreak=>'true', -labels=>$list_labels), "\n"),
			       $query->br($query->checkbox(-name=>'no_emails', -checked=>1, -value=>'ON', -label=>'do not send emails')),
			       $query->br($query->checkbox(-name=>'no_archive', -checked=>1, -value=>'ON', -label=>'do not archive online')),
			       $query->submit(-name=>'do', -value=>'send emails'), "\n",
			       $query->end_form, "\n");
    }
}

sub draw_create_list {
    my %labels = ('BCC','BCC','TO','TO');
    print "\n", $query->p("Create New List"), "\n", 
    $query->start_form, "list name: ", "\n",
    $query->textfield(-name=>'new_list_name'), "\n",
    $query->submit(-name=>'do', -value=>'create this list'), "\n",
    $query->br($query->radio_group(-name=>'new_list_type',   -values=>['BCC','TO'],   -default=>'BCC',  -labels=>\%labels )), "\n",
    $query->end_form;
}

sub delete_this_list {
    my $list_name = $query->param('list_name');

    my $delete_table_sql = "drop table $list_name;";
    my $remove_row_query = "delete from email_lists where (name = '$list_name');";

    my $sth1 = $dbh->prepare ( $delete_table_sql );
    my $sth2 = $dbh->prepare ( $remove_row_query );
    $sth1->execute;
    $sth2->execute;
    $sth1->finish();
    $sth2->finish();
    $dbh->disconnect;

    print "\n", $query->p("Deleted $list_name."), "\n";

}

sub draw_delete_list {
    my ($lists,$list_labels) = &get_list_info;

    unless ($lists) {
	print "\n", $query->p ("Sorry; there are no lists to be deleted.");
    } else {
	print "\n", $query->p("Delete List", "\n", 
			      $query->start_form(-name=>'form1'), "\n",
			      $query->br($query->radio_group(-name=>'list_name', -values=>$lists, -linebreak=>'true', -labels=>$list_labels), "\n"),
			      $query->submit(-name=>'do', -value=>'delete this list'), "(rest assured there is no undo)", "\n",
			      $query->end_form), "\n";
    }    
}

sub draw_add_names {
    my ($lists,$list_labels) = &get_list_info;

    unless ($lists) {
	print "\n", $query->p ("Sorry; there are no lists into which names can be added.");
    } else {

	if (-f $settings{'opt_out_done_filename'}) {
	    print "\n", $query->p( "<font color='#00FF00'>NOTICE</font>: these people have removed themselves from the OLD list."), "\n";
	    print "\n<font color='#FF0000'>";
	    &displayFile($settings{'opt_out_done_filename'});
	    print "</font>\n";
	}

	print "\n", $query->p( "Enter names and &lt;emails\@in.angle.brackets> below.  One email per row:", "\n",
			 $query->start_form(-name=>'form1'), "\n",
			 $query->textarea(-name=>'names',
					  -rows=>5,
					  -columns=>150), "\n",
			 $query->br($query->radio_group(-name=>'list_name', -values=>$lists, -linebreak=>'true', -labels=>$list_labels), "\n"),
			 $query->submit(-name=>'do', -value=>'submit names'), " (Add a CR after the final line!) \n",
			 $query->end_form, "\n");
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

    return (mkdef($images_admin_password) eq $settings{'robupdates password'})
}

sub logout {
    print "<a href='/cgi-bin/rob_updates.pl?" . $settings{'name of admin pw field'} . "=delete'>logout</a>";
}

sub create_this_list {
    my $listname = $query->param('new_list_name');
    my $listtype = $query->param('new_list_type');

    print "\n", $query->p("Created $listname.");

    my $create_table_sql = qq(CREATE table $listname (name VARCHAR(60) DEFAULT '', 
						      email VARCHAR(60) UNIQUE NOT NULL, 
						      id INT UNIQUE NOT NULL AUTO_INCREMENT, 
						      cksum CHAR(13) UNIQUE NOT NULL,
						      added DATE NOT NULL,
						      keep_through DATE NOT NULL,
						      removed DATE,
						      who ENUM('time', 'user' ) DEFAULT NULL,
						      language ENUM( 'English', 'Japanese' ) NOT NULL DEFAULT 'English',
						      status   ENUM( 'green', 'yellow', 'red' ) NOT NULL DEFAULT 'green',
						      key (cksum, id)););

    my $add_table_to_list_sql = qq (insert into email_lists values ("$listname", "$listtype"););

    my $sth = $dbh->prepare($create_table_sql);
    $sth->execute;
    $sth = $dbh->prepare($add_table_to_list_sql);
    $sth->execute;
    $sth->finish();
    $dbh->disconnect;
}

#: email list table
#:
#: +--------------+------------------------------+------+-----+------------+----------------+
#: | Field        | Type                         | Null | Key | Default    | Extra          |
#: +--------------+------------------------------+------+-----+------------+----------------+
#: | name         | varchar(60)                  | YES  |     |            |                |
#: | email        | varchar(60)                  |      | UNI |            |                |
#: | id           | int(11)                      |      | UNI | NULL       | auto_increment |
#: | cksum        | varchar(13)                  |      | PRI |            |                |
#: | added        | date                         |      |     | 0000-00-00 |                |
#: | keep_through | date                         |      |     | 0000-00-00 |                |
#: | removed      | date                         | YES  |     | NULL       |                |
#: | language     | enum('English','Japanese')   |      |     | English    |                |
#: | status       | enum('green','yellow','red') |      |     | green      |                |
#: +--------------+------------------------------+------+-----+------------+----------------+

sub submit_names {

    my ($row,$count,$err_count,$ok_count) = (undef,0,0,0);
    my $list_name = $query->param('list_name');
    my @email_rows;
    foreach $row (split "\n", ($query->param("names"))) {
	chomp $row;
	my (undef,$name,$email,undef,$language) = $row =~ m/(|")?([^<"]*)\1?\s*<([^>]*)>([,\s]+)(.*)/;
        if ($email) {
	    $language = mkdef($language);  # if it doesn't exist, it will default to English in mySQL
	    my $salt = join '', ('.', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
	    my $cksum = crypt($email,$salt);
	    my $Sql = "insert into $list_name values (\"$name\",'$email',0,'$cksum',NOW(),ADDDATE(NOW(), INTERVAL 1 YEAR),'00000000',NULL,'$language','green');";
	    warn ($Sql);
	    push (@email_rows, $Sql);
	    $count++;
	}
    }

    my $sth;

    # process each row that we created above
    foreach my $sql (@email_rows) {
	print $query->p($sql);
	print $query->p("1");
        $sth = $dbh->prepare($sql);
	print $query->p("2");
	$sth->execute;
	print $query->p("3");
	if ($sth->err) {
	print $query->p("4");
	    print "\n", $query->pre("$sql"), $query->p("errored: ", $sth->errstr);
	    $err_count++;
	} else {
	print $query->p("5");
	    print "\n", $query->p("ok");
	    $ok_count++;
	}
	print $query->p("6");
	$sth->finish();
	print $query->p("7");
    }

    print "\n", $query->p("Added $ok_count out of $count addresses to $list_name ($err_count errors).");

    $dbh->disconnect;
}

sub notify_rob {
    my ($body) = @_;
    my $mail_prog = "/usr/sbin/sendmail"; # location of sendmail on server;

    open(MAIL,"|$mail_prog -t");
    print MAIL "To: thunderrabbit\@gmail.com\n";
    print MAIL "From: rob_update_processor\@robnugen.com\n";
    print MAIL "Subject: IMPORTANT regarding Rob Update list!\n\n";
    print MAIL "\n$body";
    print MAIL"\n\n";
    close (MAIL);
}
    

# line_wrap written by Steve Ford 
# Copyright 1999 Steve Ford (sford AT geeky-boy (.) com) and made
# available under the Steve Ford's "standard disclaimer, policy, and
# copyright" notice.  See http://www.geeky-boy.com/standard.html for
# details.  It is based on GNU's "copyleft" and basically says that
# you can have this for free and give it to anybody else so long as
# you: 1. don't make a profit from it, 2. include this notice in it,
# and 3. you indicate any changes you made.
sub line_wrap {
    my ($msg_txt, $max_len) = @_;
    my (@in_lines, @out_lines);
    my $iline;

    if (! $max_len) {
	$max_len = 80
	}

    @in_lines = split(/\n/, $msg_txt);

    foreach $iline (@in_lines) {
	$iline =~ s/ +$//;# kill trailing spaces.

LONGLINE:
	    while (length($iline) > $max_len) {
		my $i = $max_len;
		# The reason for "i>5" is that we don't want silly short lines.
		while ($i > 5 && substr($iline, $i, 1) ne ' ') {
		    -- $i;
		}
		if ($i == 5) {
		    # Couldn't find good breaking point to the left, look right.
		    $i = $max_len;
		    while ($i < length($iline) && substr($iline, $i, 1) ne ' ') {
			++ $i;
		    }
		    if ($i == length($iline)) {
			# That's one long line!
			last LONGLINE;
		    }
		}
		push(@out_lines, substr($iline, 0, $i));
		# skip any extra spaces.
		while ($i < length($iline) && substr($iline, $i, 1) eq ' ') {
		    ++ $i;
		}
                                              # Steve Ford version:		$iline = ' ' . substr($iline, $i);  # msg lines have leading space
		$iline = substr($iline, $i);  # Rob Nugen version does not add a space at beginning of line
	    }

	push(@out_lines, $iline);
    }  # foreach iline

    return join("\n", @out_lines);
}  # line_wrap


############################################################################################################
##
##  &critical_settings_check is supposed to make sure the system is fit for use whatsoever.
##
##  Basically:
##    We must be able to read the settings files into hashes
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

    # this is the root of all settings in this project
    &hash_read(\%settings,$settings_file);
    &hash_read(\%settings,$nav_settings_file);

    # info on how to connect to the database
    unless ($settings{'dbHash file'}) {
	my $err_txt = $lang{'no dbHash file'} || "No 'dbHash file' entry in $settings_file.  It should point to a file with mySQL connection settings.";
	die with Critical_error(-text=>$err_txt);
    }
    &hash_read(\%dbHash,$settings{'dbHash file'});

    # Make sure we can get to the database.
    $dbh = &DBConnect(%dbHash);
}  # &critical_settings_check

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
    print $q->p("This is a critical error from which I cannot recover.<br /><br />Try changing $settings{'dbHash file'} or $settings_file");
    print $q->end_html;

    warn ("A critical error occured: ", $err->{"-text"});
    exit;
}

