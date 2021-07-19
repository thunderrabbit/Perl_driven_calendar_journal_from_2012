#!/usr/bin/perl -w

# July 2006: found this online somewhere and hoped to use it to extract mime attachments from emails, but it needs mime::parser and tons of shit.

# Oct 2007: I found *now* MIME:: modules are on dreamhost.  I fucked with this a bit, but couldn't get it to run.  My brain is a bit too mushy now,
# but feel free to put some effort toward this soon.

use strict;
use MIME::Parser;

my $logfile='/home/barefoot_rob/attaches.log';
my $attachdir='/home/barefoot_rob';

my $parser=new MIME::Parser;
$parser->ignore_errors(1);
$parser->extract_uuencode(1);
$parser->tmp_recycling(0);
$parser->output_to_core(1);
my $entity=$parser->parse(*STDIN);

my $from=$entity->head->get('From');
my $subject=$entity->head->get('Subject');
my @parts=$entity->parts;
my $aname='attachment001';
while(my $part = shift(@parts)) {
    if($part->parts) {
	push @parts,$part->parts; # Nested multi-part
	next;
    }
    my $type=$part->head->mime_type || $part->head->effective_type;
    if(! $type =~ m/^(text|message)/i)
    {
        # Not a text, save it
	my $filename;
	$filename=$part->head->recommended_filename || $aname;
	$aname++;
	my $io=$part->open("r");
	my $uniq=time().'-'.$$;
	$filename = s/[^-\w\.]//g;
      open(F,">> $attachdir/$uniq-$filename");
      my $buf;
	  while($io->read($buf,1024)) {
	  print F $buf;
      }
      close(F);
      $io->close;
      open(LOG,">> $logfile");
      print LOG localtime()." From: $from\tSubject: $subject\tFile: $uniq-$filename\n";
      close(LOG);
 }
}
