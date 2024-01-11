#!/usr/bin/perl -w

sub mkdef {
    my($ival) = @_;

    if (defined $ival) {
	return $ival;
    } else {
	return "";
    }
}
1;
