#!/usr/bin/perl -wT

use lib qw (.);  # allows these to be used with switch  -T (taint mode)
# to use modules installed in my user space
use lib "/home/thunderrabbit/perlmods/share/perl"; 
use lib "/home/thunderrabbit/perlmods/share/perl/5.8"; 

# load in the modules
use strict;
use CGI 3.20;

# Below usage for -T taint mode came from here:  http://www.unix.org.ua/orelly/linux/cgi/ch05_02.htm

$CGI::DISABLE_UPLOADS = 1;
$CGI::POST_MAX        = 0;   #  0 Bytes

$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

# Above usage for -T taint mode came from here:  http://www.unix.org.ua/orelly/linux/cgi/ch05_02.htm

my $q = new CGI;      # will be used for xhtml output

print $q->header(-Charset=>'utf-8', -Cache_Control=>'nocache');
print $q->start_html(-title=>'CGI Environment');

print $q->h1("CGI Environment");
foreach my $env_var (keys %ENV) {
   print $q->b($env_var) . " = $ENV{$env_var}<br />\n";
}

print "</body> </html>\n";
