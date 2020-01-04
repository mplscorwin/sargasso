#!/usr/bin/env perl
use local::lib;

use strict;
use warnings;

use Tie::File;
use IO::File;

use WebService::Dropbox;

use Time::Piece;

my $root_local_path = q(/home/sargasso/sargassoband.com);
my $local_bin_path = $root_local_path . q(/mp3/bin);
my $auth_settings_filename = $local_bin_path . q(/.dropbox-auth);
my $start_path = q(/Sargasso Mp3s); #)'';#q(id:HSZzkaUA0mwAAAAAAAAAVw);
my $local_path = $root_local_path . q(/from_dropbox);

# dropbox credentials, newline seperated: key secret token cursor
my @auth_settings;
tie @auth_settings, 'Tie::File', $auth_settings_filename
  or die qq(cannot load auth settings);
my($key,$secret,$token,$cursor) = map { chomp; $_ } @auth_settings;
die qq(dropbox auth, new-line seperated: key secret token cursor(opt))
  unless $key and $secret and $token;

sub fetch ($;$) {
  my($box,$cursor_or_path) = @_;

  my $result = ( $cursor_or_path and $cursor_or_path !~ /\//)
    ? $box->list_folder_continue( $cursor)
    : $box->list_folder($cursor_or_path, { recursive => JSON::true });
  $cursor = $auth_settings[3] = $result->{cursor} if $result->{cursor};
  return $result;
}

sub with_folder_entries(&$$) {
  my( $worker, $box, $result) = @_;
  #use Data::Dumper; warn Dumper( $result );
  $worker->($_) for @{$result->{entries}};

  if ($$result{has_more}) {
    $cursor = $auth_settings[3] = $result->{cursor} || return;
    &with_folder_entries( $worker, $box, my$new_result = fetch( $box, $cursor));
  }
}

sub fetch_latest_cursor ($;$) {
  my($box,$path) = @_;

  my $result = $box->list_folder_get_latest_cursor( $path)->{cursor};
  $cursor = $auth_settings[3] = $result if $result;
  return $cursor;
}

my $box = WebService::Dropbox->new({ key => $key, secret => $secret });
$box->access_token($token); # Authorization

my$result = fetch($box,$cursor || $start_path);
my $count = 0;
with_folder_entries {
  my $item = shift;
  my $file_path = qq($local_path$$item{path_display});
  #$file_path =~ s/[^\Sa-z0-9-_+]//ig;
  #use Data::Dumper; warn Dumper( [$file_path, $item] ); return;

  if ('folder' eq $item->{'.tag'}||'') {
    unless (-d $file_path) {
      mkdir $file_path, 0755;
      $count += 1;
      print scalar(localtime(time))." Created $file_path\n";
    }
  } elsif ('file' eq $item->{'.tag'}||'') {
    my $fh = IO::File->new( $file_path, '>');
    $box->download($$item{id}, $fh);
    #$fh->close();
    undef $fh;
    eval {
      my $mtime = Time::Piece->strptime( $$item{client_modified},'%Y-%m-%dT%H:%M:%SZ');
      my $atime = Time::Piece->strptime( $$item{server_modified},'%Y-%m-%dT%H:%M:%SZ');
      unless (1 == utime( $atime->epoch, $mtime->epoch, $file_path )) {
	warn qq[ERROR: [$file_path] failed to set a/m times [$atime,$mtime]];
      }
      my $older = $mtime > $atime ? $atime : $mtime;
      system(qq(touch -d "$older" '$file_path'));
    };
    $count += 1;
    print scalar(localtime(time))." Wrote $file_path\n";
  }
} $box, $result;

# update our cursor if we did any work
fetch_latest_cursor($box,$start_path) if $count;
