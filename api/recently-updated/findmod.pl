#!/bin/env perl



use strict;
use warnings;

use File::Find;
use File::stat;

use constant MAX_AGE => 2 * 24*60*60;   # 2 days
use constant MIN_ITEMS => 10;




{
  my @newest = findNewest(MAX_AGE, MIN_ITEMS);
  

}



sub findNewest {
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

  return @dates;
}




