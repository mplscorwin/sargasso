#!/usr/bin/env perl
use local::lib;

use strict;
use warnings;

use WebService::Dropbox;

use Tie::File;

my $auth_settings_filename = q(.dropbox-auth);
my @auth_settings;
tie @auth_settings, 'Tie::File', $auth_settings_filename
  or die qq(cannot load auth settings);

my($key,$secret,$token,$cursor) = map { chomp; $_ } @auth_settings;

die qq(key and secret must be the first two lines of $auth_settings_filename)
  unless $key and $secret;

my $box = WebService::Dropbox->new({ key => $key, secret => $secret });

# Authorization
if ($token) {
    $box->access_token($token);
} else {
    my $url = $box->authorize;

    print "Please Access URL and press Enter: $url\n";
    print "Please Input Code: ";

    chomp( my $code = <STDIN> );

    unless ($box->token($code)) {
	die $box->error;
    }

    print "Successfully authorized.\nYour AccessToken: ", $box->access_token, "\n";
    $auth_settings[2] = $box->access_token;
}

my $info = $box->get_current_account or die $box->error;
use Data::Dumper; print Data::Dumper::Dumper( $info );

