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
  my ($root, $path, $time) = @_;
  my $mrtime = strftime("%Y-%m-%dT%H:%M:%S%z\n", localtime($time));
  my $htime = localtime($time);

  return <<EOF
<li><a class="homepage-link" href="$root">$path</a>
<time datetime="$mrtime">$htime</time></li>
EOF
}

sub json {
  my ($root, $path, $time) = @_;
  my $mrtime = strftime("%Y-%m-%dT%H:%M:%S%z\n", localtime($time));
  my $htime = localtime($time);

  return <<EOF
EOF
}

{
  my $root = "http://`hostname`";
  chomp($root);

  my @updated = getUpdated();
  my $html = join("", map{ html( $root, @{$_} ) } @updated);
  spew("tilde.24h.html", <<"EOF");
<!DOCTYPE html>
<html><head><title>tilde.24h</title></head>
<body>
<h1>tilde.club home pages updated in last 24 hours</h1>
<p>There's also <a href="tilde.24h.json">a JSON version of this data</a>;
it's all updated once a minute, so hold yer damn horses, people. Also, times
are in the server's time zone (GMT, it appears).</p>
<ul>$html</ul>
</body>
</html>
EOF

  my $json = join("", map{ json( @{$_} ) } @updated);
  

}
