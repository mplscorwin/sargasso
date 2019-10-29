#!/usr/bin/perl

use strict;
use warnings;

use local::lib;

use File::Find;
use Music::Tag;

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);
my $mp3info   = $home . q(/bin/mp3info);

my $ok_types = join '|', qw[mp3 m4a m4p mp4 m4b 3gp ogg flac]; #/.m(?:4a|p3)$/
our $START_HTML;

my $first = 1; #bit of an hack here for JSON commafication

print qq(Content-type: application/json\n\n);
print '[';
find( \&wanted, $startpath);
print ']';
sub wanted {
  my $file = $File::Find::name;
  if($file =~ /\.(?:$ok_types)$/i and ! -d $file) {
    my $path = rmpath( $file );
    my $info = new Music::Tag( $file, {quiet=>1} );
    $info->get_tag();
    my $total_secs = $info->secs;
    my $min = int( $total_secs / 60);
    my $secs = sprintf("%02d", $total_secs % 60 == 0 ? 0 : $total_secs - ($min * 60));
    my $artist = $info->artist || '<unlabled>';
    my $album = $info->album || '<unlabled>';
    my $title = $info->title || '<unlabled>';
    print ',' unless $first-- > 0;
    print qq<{"artist":"$artist","album":"$album","title":"$title","dttm":"$min:$secs","secs":$total_secs,"path":"$path"}>;
  }
}

sub rmpath {
  my $path = shift;
  $path =~ s/\Q$startpath\E//;
  return $path;
};
