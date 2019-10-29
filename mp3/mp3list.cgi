#!/usr/bin/perl

use strict;
use warnings;

use local::lib;

use CGI;
use File::Find;
use Music::Tag;

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);
my $mp3info   = $home . q(/bin/mp3info);

my $ok_types = join '|', qw[mp3 m4a m4p mp4 m4b 3gp ogg flac]; #/.m(?:4a|p3)$/
our $START_HTML;

print CGI->header;
print <DATA>;
find( \&wanted, $startpath);
print "</table></div></div></body></html>";
sub wanted {
  my $file = $File::Find::name;
  if($file =~ /\.(?:$ok_types)$/i and ! -d $file) {
    my $path = rmpath( $file );
    my $info = new Music::Tag( $file );
    $info->get_tag();

    my @info = do {
      my $total_secs = $info->secs;
      my $min = int( $total_secs / 60);
      my $secs = $total_secs % 60 == 0 ? 0 : $total_secs - ($min * 60);
      my $artist = $info->artist;
      my $album = $info->album;
      my $title = $info->title;
      ($min, $secs, $artist, $album, $title)
    };
    
    #my @info = split /\t/, `$mp3info -p "%m\t%s\t%a\t%l\t%t" "$file" 2>/dev/null`;
    ##my $dur = `$mp3info -p "%m:%s\t%a\t%l\t%t" "$file" 2>/dev/null`;
    $info[1] = sprintf("%02d",$info[1]);
    $info[$_] ||= '<unlabled>' for 2..4;
    ##my $dur = join "\t", @info;
    ##print qq($dur\t$path\n);

    print "    <tr><td>$info[2]</td><td>$info[3]</td><td>$info[4]</td><td>$info[0]:$info[1]</td><td><a href=\"$path\">$path</a></td></tr>\n";
  }
}

sub rmpath {
  my $path = shift;
  $path =~ s/\Q$startpath\E//;
  return $path;
};


__DATA__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>Sargasso - MP3 List</title>
<link rel="stylesheet" href="mp3.css" />
<style type="text/css">
</style>
</head>
<body>
<body>
<div class="outterFrame" id="outterFrameDiv">
  <div class="innerFrame" id="innerFrameDiv">
  <img src="/wp-content/uploads/2019/07/cropped-shadowfedora.jpg" alt="Project_Header_Image" />
  <h3 class="titleColor">Sargasso MP3 List</h3>
  <table>
    <tr><td>Artist</td><td>Album</td><td>Title</td><td>Duration</td><td>Link</td></tr>
