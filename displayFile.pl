use strict;
use warnings;

sub displayFile
{
    # $_[0] points to the first argument in the argument array @_;
    if (-f $_[0]) {
        open(my $in, '<', $_[0]) or die "Can't open $_[0] for reading";
        while (<$in>) {
            print;
        }
        close $in or die "Can't close $_[0]";
    }
}
1;
