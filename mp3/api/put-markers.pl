#!/usr/bin/perl

use strict;
use warnings;

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
