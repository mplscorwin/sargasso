#!/usr/bin/perl

use strict;
use warnings;

use File::Find;

use CGI;
use CGI::Carp qw[fatalsToBrowser];

use local::lib;
use Music::Tag;
use MP3::Tag;
MP3::Tag->config(write_v24 => 1);

my $home      =    q(/home/sargasso);
my $startpath = $home . q(/sargassoband.com);
my $linkpre   =   q(http://sargassoband.com);
my @exposed_fields = qw[title artist album];

my $q = new CGI;
my( $path ) = $q->multi_param('path') or die qq(path is required);
my $mp3_filepath = $startpath . $path;
die "no such path" unless -f $mp3_filepath;

my $info = new Music::Tag( $mp3_filepath, { quiet => 1 } );
$info->get_tag();

$q->param($_) and $info->$_( [ $q->multi_param($_)]->[0]) for @exposed_fields;
$info->set_tag() or die qq(failed to update tags);
$info->close() or die qq(failed to close file);

print qq(Content-type: application/json\n\ntrue);
exit();

__END__
