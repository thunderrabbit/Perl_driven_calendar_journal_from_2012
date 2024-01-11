#!/usr/bin/perl -w
######################################################################
#
# hash_io.pl reads and writes hashes; designed to bring in settings for perl scripts
# version 0.0
#
# Copyright (C) 2006 Rob Nugen
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

######################################################################
#
#  Revisions
#  0.0 (11 June 2006) creation, based on displayFile.pl
#
######################################################################

use strict;
require "mkdef.pl";

sub hash_read {
    my ($hash_ptr, $infile) = @_;

    die with Critical_error(-text=>"$infile is not a file.") unless (-f $infile);

    open (IN, $infile) or die with Critical_error(-text=>"Can't open $infile for reading");

    while (<IN>) {
	chomp;
	my($key,$value) = split ("=>",$_);
	if ($key) {
	    mkdef($key); mkdef($value);
	    $key =~ s/^\s+//;   # remove whitespace from the ends of the $key and $value
	    $key =~ s/\s+$//;
	    $value =~ s/^\s+//;
	    $value =~ s/\s+$//;
	    $$hash_ptr{$key} = mkdef($value);
	}
    }
    close IN or warn "Couldn't close $infile, but continuing anyway.";
}

1;
