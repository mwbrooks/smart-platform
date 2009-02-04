package RSP::JSObject::MediaFile;

use strict;
use warnings;

use Digest::MD5;
use LWP::UserAgent;
use File::MMagic::XS qw(:compat);
use base 'RSP::JSObject';

sub new {
  my $class = shift;
  my $mog   = shift;
  my $tx    = shift;
  my $name  = shift;
  my $paths = shift;
  my $self  = { mog => $mog, tx => $tx, paths => $paths, name => $name };
  bless $self, $class;
}

sub jsclass {
  return 'MediaFile';
}

sub properties {
  return {
	  filename => {
		       'getter' => 'RSP::JSObject::MediaFile::filename',
		      },
	  mimetype => {
		       'getter' => 'RSP::JSObject::MediaFile::mimetype'
		      },
	  size     => {
		       'getter' => 'RSP::JSObject::MediaFile::size',
		      },
	  length   => {
		       'getter' => 'RSP::JSObject::MediaFile::size',
		      },
	  digest   => {
		       'getter' => 'RSP::JSObject::MediaFile::md5',
		      },
	 };
}

sub methods {
  return {
	  'remove' => 'RSP::JSObject::MediaFile::remove'
	 };
}

sub remove {
  my $self = shift;
  $self->{mog}->delete( $self->filename );
  $self->clearcache( $self->{tx}, $self->filename );
}

sub clearcache {
  my $class  = shift;
  my $tx     = shift;
  my $fname  = shift;
  foreach my $key ( (keys %{ $class->properties }, 'content')) {
    $tx->cache->delete( $class->cachename( $key, $fname ) );
  }
}

sub cachename {
  my $self = shift;
  my $what = shift;
  if (!$what) {
    die "no data type key";
  }
  my $name = shift;
  if (!$name) {
    if ( ref($self) ) {
      $name = $self->{name};
    } else {
      die "no name";
    }
  }
  if (!$what) { die "no type for cache name" }
  return join(":", "__mogilefs__", $what, $name);
}

sub cached_getandset {
  my $self = shift;
  my $what = shift;
  my $gen  = shift;
  my $cachekey = $self->cachename( $what );
  if ( $self->{ $what } ) {
    return $self->{ $what };
  } else {
    my $cached = $self->{tx}->cache->get( $cachekey );
    if (!$cached) {
      $cached = $gen->();
      $self->{tx}->cache->set( $cachekey, $cached );
    }
    $self->{ $what } = $cached;
  }
  return $self->{ $what };
}

sub md5 {
  my $self = shift;
  $self->cached_getandset( 'digest', sub { Digest::MD5::md5_hex( $self->contents ) } );
}

sub filename {
  my $self = shift;
  return $self->{name};
}

sub mimetype {
  my $self = shift;
  $self->cached_getandset(
			  'mimetype', sub {
			    my $mm   = File::MMagic::XS->new;
			    return $mm->checktype_contents( $self->contents );
			  }
			 );
}

sub size {
  my $self = shift;
  $self->cached_getandset(
			  'size',
			  sub {
			    return bytes::length( $self->contents );
			  }
			 );
}

sub contents {
  my $self = shift;
  $self->cached_getandset(
			  'content',
			  sub {
			    my $ua = LWP::UserAgent->new;
			    foreach my $path (@{ $self->{paths} }) {
			      my $response = $ua->get($path);
			      if ( $response->is_success ) {
				return $response->content;
			      }
			    }
			  }
			 );
}

sub as_string {
  my $self = shift;
  return $self->contents;
}

1;
