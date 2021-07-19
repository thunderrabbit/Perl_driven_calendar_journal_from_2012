#!/usr/bin/perl

# selects a random email address each time it's called

print "Content-type: text/html\n\n";

$DOMAIN = "robnugen.com";
$EMAIL_USERNAME_FILE = "/home/barefoot_rob/temp.robnugen.com/random_email_usernames.txt";

open (IN, "$EMAIL_USERNAME_FILE") or die "Can't open $EMAIL_USERNAME_FILE for reading";
while (<IN>) {
    chomp;
    push (@array,$_);
}
close IN                or die "Can't close $EMAIL_USERNAME_FILE";

$key = int rand ($#array+1);

# the idea here is I can override what's displayed to user if I send it as a parameter
# but for now I don't know how to send parameters.
$display = "$array[$key]\@$DOMAIN";

print "<a href=\"mailto:$array[$key]\@$DOMAIN\">$display</a>";


