#!/usr/bin/perl
# create new files from regions
##ffmpeg -i sargasso-july-2018.mp3 -codec copy -ss 50 -to 70 out.mp3
use strict;
use warnings;

use local::lib;

use File::Find;
use Music::Tag;

use CGI;
use CGI::Carp qw[fatalsToBrowser];

use JSON qw[decode_json];

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $outfolder   = $startpath . q(/mp3/cuts/);
my $linkpre   =   q(http://sargassoband.com);

my $q = new CGI;
my( $path ) = $q->multi_param('path') or die qq(path is required);
my $mp3_filepath = $startpath . $path;
die "no such path" unless -f $mp3_filepath;
my $marker_filepath = $mp3_filepath . '-markers';
unless (-T $marker_filepath) {
  print qq(Content-type: application/json\n\nfalse);
  exit;
}

my $markers = do  {
  open my$FH, '<', $marker_filepath or die qq(cannot read markers);
  decode_json( join '',<$FH>)
};
foreach(@$markers) {
  #use Data::Dumper; die Dumper($_);
  my $title=$_->{qq(title)} or next;
  $title =~ s/\s+/-/g;
  $title =~ s/[^a-z0-9+-]//ig;
  next unless $title and $title =~ /[^+-0-9]/;
  my $cmd = qq(ffmpeg -y -loglevel quiet -i "$mp3_filepath" -codec copy -ss $$_{start} -to $$_{end} "${outfolder}${title}.mp3");
  system( $cmd ) and die "($?) $@ -- $@";
}
print qq(Content-type: application/json\n\ntrue);
__END__

print qq(Content-type: application/json\n\ntrue);
#print $q->header(); # $q->header("application/json");
#print "<h1>ok</h1>";
#print qq(Content-type: application/json\n\ntrue);
exit();

__END__
print qq(Content-type: application/json\n\n);
print '[';
find( \&wanted, $startpath);
print ']';
sub wanted {
  my $file = $File::Find::name;
  if($file =~ /\.(?:$ok_types)$/i and ! -d $file) {
    my $path = rmpath( $file );
    my $info = new Music::Tag( $file );
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


#use local::lib;

#use CGI::Carp qw[fatalsToBrowser];
use CGI;

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);

my $q = new CGI;
my( $path ) = $q->multi_param('path') or die qq(path is required);
my( $json ) = $q->multi_param('markers') or die qq(marker data is required);
my $mp3_filepath = $startpath . $path;
die "no such path" unless -f $mp3_filepath;
my $marker_filepath = $mp3_filepath . '-markers';
open my$FH, '>', $marker_filepath or die qq(can't open marker file; $!);
#print $FH qq(Content-type: application/json\n\n);
print $FH $json;
close $FH;
print qq(Content-type: application/json\n\n);
print "true";
