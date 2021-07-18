#!/usr/bin/perl -w
######################################################################
#
# DB_CDE contains the messy details of db connection
# version 0.0
#
# Copyright (C) 2006 Rob Nugen
#  DBI code taken (with permission) from Mike Schienle's article at
#  http://www.oreillynet.com/pub/a/mac/2004/05/07/iphoto_perl.html
# 
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
#
######################################################################

use DBI;

# DB connection subroutine
sub DBConnect {
  my %dbHash = @_;
  my $dbh;

  my $data_source_name = join ':', "DBI", $dbHash{'dbType'}, $dbHash{'dbName'}, $dbHash{'dbHost'};

  # attributes
  my %attr = (
    PrintError => 0,
    RaiseError => 1,
    ShowErrorStatement => 1
  );

  # connection command
  eval {
      # Accoding to http://search.cpan.org/~timb/DBI/DBI.pm#RaiseError, with RaiseError on, we must catch an exception if there is an error
      $dbh = DBI->connect($data_source_name, $dbHash{'dbUser'}, $dbHash{'dbPass'}, \%attr);
  };
  if ($@) {  # $@ is a lengthy error message
      die with Critical_error (-text=>$@ . "- cannot connect to " . $data_source_name);
  }
  else 
  {
      return $dbh;
  }
}


# DB disconnect subroutine
sub DBDisconnect {
  $dbh->disconnect()
    or DBError("Cannot disconnect from DB");
}

# DB error subroutine
sub DBError {
  my $message = shift;
  # display a message
  warn "$message\nError $DBI::err- $DBI::errstr\n";
  return 0;
}
1;
