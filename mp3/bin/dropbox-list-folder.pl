#!/usr/bin/env perl
use local::lib;

use strict;
use warnings;

use WebService::Dropbox;

use Tie::File;

sub list_folder(&$$) {
  my( $worker, $box, $result) = @_;

  for my$item(@{$result->{entries}}) {
    $worker->($item);
    #print "$$item{id}\t$$item{path_display}\n"
  }

  if ($$result{has_more}) {
    my $new_result = $box->list_folder_continue($$result{cursor});
    #&list_folder($box,$new_result);
    &list_folder($worker,$box,$new_result);
  }
}

my $auth_settings_filename = q(.dropbox-auth);
my $start_path = q(/Sargasso Mp3s); #)'';#q(id:HSZzkaUA0mwAAAAAAAAAVw);
my @auth_settings;
tie @auth_settings, 'Tie::File', $auth_settings_filename
  or die qq(cannot load auth settings);
my($key,$secret,$token) = map { chomp; $_ } @auth_settings;
die qq(key and secret and token must be the first three lines of $auth_settings_filename)
  unless $key and $secret and $token;
my $box = WebService::Dropbox->new({ key => $key, secret => $secret });
$box->access_token($token); # Authorization

my $result = $box->list_folder($start_path, {
					     recursive => JSON::true,
					     include_media_info => JSON::true,
					     include_deleted => JSON::false,
					     include_has_explicit_shared_members => JSON::true
					    });


list_folder { my$item=shift;print "$$item{id}\t$$item{path_display}\n" } $box, $result;
#use Data::Dumper; die Dumper( $result );

__END__
if ($token) {
    
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

