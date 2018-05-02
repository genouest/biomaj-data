#!/usr/bin/perl

# Requires Net::Twitter perl library.
# Update TOBEUPDATED with your twitter account app data 

use Getopt::Std;
use Net::Twitter;
use Scalar::Util 'blessed';


$message = "Bank ".$ENV{'dbname'}." updated with version ".$ENV{'remote
release'}.".";
print STDOUT "Tweet Message: ".$message."\n";

my $nt = Net::Twitter->new(
      traits   => ['API::REST','OAuth'],
      consumer_key => 'TOBEUPDATED',
      consumer_secret => 'TOBEUPDATED'
  );

      $nt->access_token('TOBEUPDATED');
      $nt->access_token_secret('TOBEUPDATED');

  unless ( $nt->authorized ) {
      # The client is not yet authorized: Do it now
      print STDERR "Application not authorized\n";
      die "auth error";
  }

  # Everything's ready

  my $result = eval { $nt->update($message) };

  if ( my $err = $@ ) {
      die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

      print STDERR "HTTP Response Code: ", $err->code, "\n";
      print STDERR  "HTTP Message......: ", $err->message, "\n";
      print STDERR  "Twitter error.....: ", $err->error, "\n";
  }
