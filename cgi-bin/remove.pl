#!/usr/bin/perl -w

######################################################################
#
# remove.pl keeps track of requests to be removed from my mass email
# lists.  Users don't have my mySQL password, so this writes the
# requests to a flatfile which is read and processed by
# rob_update_mailer.pl before any other processing is done.
#
# Copyright 2005 Rob Nugen
# Feel free to copy this and change it, so long as you give me
# appropriate credit, document your changes, and make the source
# available to whoever wants it. http://robnugen.com/copyright.html
#
######################################################################

require "allowSource.pl";
require "setCookies.pl";
require "mkdef.pl";

# require "rob_update_setup.pl";   # I don't know how to do this and use strict.  So the next couple lines are the contents of this file
# BEGIN rob_update_setup.pl
my $public_html_dir = "/home/thunderrabbit/public_html";
my $update_directory = "/travel/japan/pre-pb52";
my $opt_out_q_filename = "$public_html_dir$update_directory/DO_NOT_DELETE_opt_outs.txt";
my $opt_out_done_filename = "$public_html_dir/DO_NOT_DELETE_opted_out_of_rob_updates.txt";
my $semaphore_filename =  "$public_html_dir$update_directory/semaphore_file_should_vanish.txt";
my $remove_pl = "remove.pl";
# END rob_update_setup.pl

use strict;
use CGI qw(:all fatalsToBrowser);

my ($id,$cksum,$list_name,$confirmed);
my $query = new CGI;

$id = mkdef($query->param('id'));
$cksum = mkdef($query->param('ck'));
$list_name = mkdef($query->param('l'));
$confirmed = mkdef($query->param('sure'));

print $query->header, $query->start_html("Rob Updates");

unless ($id && $cksum && $list_name) {

    # $id, $cksum, $list_name must be defined.  
    # This will be executed if some mucked up params are sent to
    # remove.pl (by hand, most likely)
    print $query->p("There was a problem.  Please send me an email at <a href='mailto:rob\@robnugen.com'>rob\@robnugen.com</a> to be removed.");
    &notify_rob("This link didn't work at all: http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}");

} elsif (-f $semaphore_filename) {

    # The semaphore file exists; someone else clicked at the same
    # time.  This user could probably click again and be fine, but an
    # email is being sent so I can click for them.
    print $query->p("You'll be off the list soon.");
    &notify_rob("Server was busy (semaphore existed) click again: http://$ENV{'HTTP_HOST'}$ENV{'REQUEST_URI'}");
} elsif ($confirmed eq "") {
    my $URL = "http://robnugen.com/cgi-bin/$remove_pl?id=$id&ck=$cksum&l=$list_name&sure=yes";
    print $query->p("Confirm:");
    print $query->p("Click ", $query->a({-href=>$URL}, "here"), " to be removed from $list_name\n");
} else {
    # All is good; create the semaphore file
    open(SEMAPHORE, ">$semaphore_filename");
    print SEMAPHORE "removing $id $cksum from $list_name";
    close(SEMAPHORE);

    # update the opt-out file
#-OLD    open(OUT, ">>$opt_out_q_filename");
#-OLD    print OUT join (":",('remove',$id,$cksum,"$list_name")), "\n";
    open(OUT, ">>$opt_out_done_filename");
    print OUT "REMOVE $id, $cksum of $list_name from current list. then remove from $opt_out_done_filename.<br>If this becomes annoying, restore -OLD code in remove.pl and fix it so rob_update_mailer displays the name, not just id here\n";
    close(OUT);
    print $query->p("You have been removed from the list..");

    # remove the semaphore file
    unlink ("$semaphore_filename");  # the next process can do its thing
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

&allowSource;

print $query->end_html;
