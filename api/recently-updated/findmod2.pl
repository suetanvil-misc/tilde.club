#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
use POSIX 'strftime';

use constant THEN => time() - 24*60*60;
#use constant ROOT => '';

# Search through the public_html directories for the most recent file
# and add the dir. path and latest update time to @updated if it is
# more recent than 24 hours ago.
sub getUpdated {
  my @updated = ();

  for my $home (glob "/home/*/public_html") {
    my $latest = 0;
    find(sub {
           my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
               $atime,$mtime,$ctime,$blksize,$blocks)
             = stat($_);
           $latest = $mtime if $latest < $mtime;
         }, $home);
    push @updated, [$home, $latest] if $latest >= THEN;
  }

  # Sort from most recent to least recent
  @updated = sort {$b->[1] <=> $a->[1]} @updated;

  return @updated;
}

sub spew {
  my ($filename, $text) = @_;

  open my $fh, ">", $filename
    or die "Unable to open '$filename' for writing.\n";
  print {$fh} $text;
  close($fh);
}

sub html {
  my ($path, $
}

{
  my $root = "http://" . chomp(`hostname`);

  @updated = getUpdated();
  # my $html = join("",
  #                 map{
  #                   "<li><a class=\"homepage-link\" href=\"$root\">$_->[0]</a>".
  #                     "<time datetime=\""

}
