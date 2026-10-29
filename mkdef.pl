#!/usr/bin/perl -w
use strict;
use warnings;

sub mkdef {
    my($ival) = @_;

    if (defined $ival) {
        return $ival;
    } else {
        return "";
    }
}
1;
