#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
no warnings 'File::Find';
use POSIX 'strftime';
use File::Basename;
use File::Spec;


{
  my $root = guessRoot();
  my $window = 24;

  my @updated = getUpdated($window);

  my $html = join("", map{ html( $root, @{$_} ) } @updated);
  spew("tilde.${window}h.html", <<"EOF");
<!DOCTYPE html>
<html><head><title>tilde.${window}h</title></head>
<body>
<h1>tilde.club home pages updated in last $window hours</h1>
<p>There's also <a href="tilde.${window}h.json">a JSON version of this data</a>;
it's all updated once a minute, so hold yer damn horses, people. Also, times
are in the server's time zone (GMT, it appears).</p>
<ul>$html</ul>
</body>
</html>
EOF

  my $json = join("", map{ json( $root, @{$_} ) } @updated);
  spew("tilde.${window}h.json", "{ \"pagelist\" : [\n$json]}\n");
}

sub guessRoot {
  my $root = `hostname`;
  chomp $root;
  return "http://$root/";
}


sub getUpdated {
  my ($window) = @_;
  my $then = time() - $window*60*60;

  my @updated = ();

  for my $home (glob "/home/*") {
    my $ph = "$home/public_html";
    next unless -r $ph;

    my $latest = 0;
    my $page = "";
    my $uname = basename($home);
    find(sub {
           my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
               $atime,$mtime,$ctime,$blksize,$blocks)
             = stat($_);
           return unless -f;
           if($latest < $mtime) {
             $latest = $mtime;
             $page = File::Spec->abs2rel($File::Find::name, $ph);
           }
         }, $ph);
    push @updated, [$uname, $latest, $page]
      if $latest >= $then;
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

sub xmltime { strftime('%Y-%m-%dT%H:%M:%S%z', localtime($_[0])); }

sub html {
  my ($root, $user, $time, $file) = @_;
  my $mrtime = xmltime($time);
  my $htime = localtime($time);

  return <<EOF
<li>
  <a href="${root}~${user}">$user</a>
  (<a href="${root}~${user}/${file}">$file</a>)
  <time datetime="$mrtime">$htime</time>
</li>
EOF
}

sub json {
  my ($root, $user, $time, $file) = @_;
  my $mrtime = xmltime($time);
  my $url = "${root}~${user}";
  my $fileUrl = "$url/$file";

  return <<EOF
{  "username" : "$user",
   "homepage" : "$url",
   "modtime" : "$mrtime",
   "changed" : "$fileUrl"},
EOF
}

