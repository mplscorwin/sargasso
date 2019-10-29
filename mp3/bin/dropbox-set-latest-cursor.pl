#!/usr/bin/env perl
use local::lib;

use strict;
use warnings;

use WebService::Dropbox;

use Tie::File;
use IO::File;

my $auth_settings_filename = q(.dropbox-auth);
my $start_path = q(/Sargasso Mp3s); #)'';#q(id:HSZzkaUA0mwAAAAAAAAAVw);

my @auth_settings;
tie @auth_settings, 'Tie::File', $auth_settings_filename
  or die qq(cannot load auth settings);

# dropbox credentials are stored one item per line
# in this order: key secret token cursor
my($key,$secret,$token,$cursor) = map { chomp; $_ } @auth_settings;
die qq(key and secret and token must be the first three lines of $auth_settings_filename)
  unless $key and $secret and $token;

sub fetch_latest_cursor ($;$) {
  my($box,$path) = @_;
  my $result = $box->list_folder_get_latest_cursor( $path)->{cursor};
  $cursor = $auth_settings[3] = $result if $result;
  return $cursor;
}

my $box = WebService::Dropbox->new({ key => $key, secret => $secret });
$box->access_token($token); # Authorization

print qq(Current cursor: $cursor\n);
fetch_latest_cursor($box,$start_path);
print qq(Updated cursor: $cursor\n);
