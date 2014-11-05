#!/bin/env perl



use strict;
use warnings;

use File::Find;
use File::stat;

use Getopt::Long;

# Defaults
use constant MAX_AGE => 24;


{
  my $maxAge = MAX_AGE;
  my $minItems = MIN_ITEMS;

  my @newest = findNewest($maxAge * 3600);

  makeHtml(MAX_AGE, @newest);
}


sub makeHtml {
  my ($maxAge, @newest) = @_;




}

sub findNewest {
  my ($maxAge) = @_;

  my @dates = ();

  for my $path (glob '/home/*/public_html') {
    next unless -d $path;

    my $latest = 0;
    find(sub {
           return unless -f;
           my $t = stat($_)->mtime;
           $latest = $t > $latest ? $t : $latest;
         },
         $path);
    push @dates, [$path, $latest];
  }

  @dates = sort {$a->[1] <=> $b->[1]} @dates;

  # Discard all dates older than $maxAge seconds ago
  my $earliest = time() - $maxAge;
  return grep { $_->[1] > $earliest } @dates;
}




