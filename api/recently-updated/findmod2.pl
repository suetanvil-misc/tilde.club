#!/usr/bin/perl

use strict;
use warnings;

use File::Find;
no warnings 'File::Find';
use POSIX 'strftime';
use File::Basename;
use File::Spec;

use Getopt::Long;

{
  my $domain = guessRoot();
  my $root = undef;
  my $window = 24;
  my $help;
  my $destdir = ".";
  my $updatePeriod = 60;

  my @opts = ('domain=s'        => \$domain,
              'root=s'          => \$root,
              'since-hours=i',  => \$window,
              'destdir=s'       => \$destdir,
              'update-every=i', => \$updatePeriod,
              'help'            => \$help);
  GetOptions(@opts) or die "Invalid option; try '--help'.\n";

  if ($help) {
    print "USAGE: $0 " . join(" ", map{"[--$_]"} grep{/^[a-z]/} @opts) . "\n";
    exit 0;
  }

  $root ||= "http://$domain/";

  do {
    my @updated = getUpdated($window);

    my $html = join("", map{ html( $root, @{$_} ) } @updated);
    spew("$destdir/tilde.${window}h.html", <<"EOF");
<!DOCTYPE html>
<html><head><title>$domain Updates (last $window hours)</title></head>
<body>
<h1>${domain} home pages updated in last $window hours</h1>
<p> Times are in the server's time zone.</p>
<p> There's also <a href="tilde.${window}h.json">a JSON version of this
    data</a>.</p>
<ul>$html</ul>
</body>
</html>
EOF

    my $json = join("", map{ json( $root, @{$_} ) } @updated);
    spew("$destdir/tilde.${window}h.json", "{ \"pagelist\" : [\n$json]}\n");

    sleep($updatePeriod) if $updatePeriod > 0;
  } while($updatePeriod > 0);
}

sub guessRoot {
  my $domain = `hostname`;
  chomp $domain;
  return $domain;
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

