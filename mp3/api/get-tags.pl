#!/usr/bin/perl
use strict;
use warnings;

use CGI;
use CGI::Carp qw[fatalsToBrowser];

#use local::lib;

use Music::Tag;

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);

my $q = new CGI;
my( $path ) = $q->multi_param('path') or die qq(path is required);
my $mp3_filepath = $startpath . $path;
die "no such path" unless -f $mp3_filepath;

my $info = new Music::Tag( $mp3_filepath, { quiet => 1 } );
$info->get_tag();
print qq(Content-type: application/json\n\n\{);
print join ",", map { my( $tag, $val ) = ($_, $info->$_);
		      qq("$tag":"$val")
		    } qw[title artist album];
print '}';
exit();

__END__

#use CGI::Carp qw[fatalsToBrowser];
use CGI;

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);

my $q = new CGI;
my( $path ) = $q->multi_param('path') or die qq(path is required);
my $mp3_filepath = $startpath . $path;
die "no such path" unless -f $mp3_filepath;
my $marker_filepath = $mp3_filepath . '-markers';
if (-T $marker_filepath) {
  open my$FH, '<', $marker_filepath or die qq(can't open marker file; $!);
  print qq(Content-type: application/json\n\n);
  print <$FH>;
  close $FH;
} else {
  #die $marker_filepath;
  print qq(Content-type: application/json\n\n[]);
}
exit();
