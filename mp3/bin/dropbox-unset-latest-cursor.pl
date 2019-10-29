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

print qq(Current cursor: $cursor\n);
undef $auth_settings[3];
print qq(Removed cursor\n);
