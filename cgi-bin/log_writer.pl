#!/usr/bin/perl
####################################################################
#
# log_writer.pl is my technique of writing interesting happenings to
# various logfiles.
#
# Copyright (C) 2006 Rob Nugen  log_writer@robnugen.com
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

use strict;
use CGI;
use CGI::Cookie;
require "mkdef.pl";

my %filenames_hash = 
    (
     journal => "/home/barefoot_rob/temp.robnugen.com/safe/journal_log.txt",
     source => "/home/barefoot_rob/temp.robnugen.com/safe/source_log.txt",
     daysold => "/home/barefoot_rob/temp.robnugen.com/safe/daysold_log.txt",
     spam => "/home/barefoot_rob/temp.robnugen.com/safe/spam_log.txt",
     "images.v0.003" => "/home/barefoot_rob/temp.robnugen.com/safe/images.v0.003_log.txt",
     general => "/home/barefoot_rob/temp.robnugen.com/safe/general_log.txt"
     );

sub write_log {
    my ($which_file, $what_to_write) = @_;

    my %cookies_read = fetch CGI::Cookie;
    my ($name,$email);
    if ($cookies_read{'name'}) {
	$name=$cookies_read{'name'} -> value;
    }

    if ($cookies_read{'email'}) {
	$email=$cookies_read{'email'} -> value;
    }

    $what_to_write = "DEETS: " . $what_to_write unless ($what_to_write =~ m/DEETS/m);
    $what_to_write = "TIMESTAMP " . $what_to_write unless ($what_to_write =~ m/TIMESTAMP/m);

    my $deets = join (" ", $ENV{REMOTE_ADDR}, &mkdef($name), &mkdef($email));
    $what_to_write =~ s/DEETS/$deets/s;

    # I'd like this to be in YYYY/MM/DD HH:MM:SS format for sorting purposes, but this will do for now
    my $timestamp = localtime;
    $what_to_write =~ s/TIMESTAMP/$timestamp/s;

    my $log_filename;
    unless ($log_filename = $filenames_hash{$which_file})
    {
	$log_filename = $filenames_hash{'general'};
	$what_to_write = $which_file . ": " . $what_to_write;
    }
	

    if ($ENV{'REMOTE_ADDR'}) {
	if ($ENV{'REMOTE_ADDR'} =~ /66\.249\.(65|66|67|68|69|7|8|90|91|92|93|94|95)/) {
	    $log_filename = "$log_filename.google";
	}
    }

    open LOGFILE, ">>$log_filename" or die "can't open $log_filename: $!";
    print LOGFILE  "$what_to_write\n";
    close LOGFILE;
}


