package RSP::Extension::HTTP;

use Moose;

with qw(RSP::Role::Extension RSP::Role::Extension::JSInstanceManipulation);

use Encode;
use HTTP::Request;
use LWPx::ParanoidAgent;

use Try::Tiny;

our $VERSION = '1.00';

sub bind {
    my ($self) = @_;

    $self->bind_extension({
        http => {
            request => $self->generate_js_closure('http_request'),
        },
    });
}

## why does LWPx::ParanoidAgent need this?
{
    no warnings 'redefine';
    sub LWP::Debug::debug { }
    sub LWP::Debug::trace { }
}

sub http_request {
    my ($self, @js_args) = @_;

    my $ua = LWPx::ParanoidAgent->new;
    $ua->agent("Joyent Smart Platform / HTTP / $VERSION");
    $ua->timeout( 10 );

    my $response = try {
        my @args;
        for my $part (@js_args){
            push(@args, (
                ref($part) ? $part : Encode::encode("utf8", $part)
            ));
        }

        my $req = shift @args;
        my $r = ref($req) ? HTTP::Request->new(@$req) : HTTP::Request->new($req, @args);
        $ua->request( $r );
    } catch { 
        die "Could not complete HTTP Request: $_";
    };

    my $ro = $self->response_to_object($response);
    return $ro;
}

sub response_to_object {
  my $class = shift;
  my $response = shift;
  my %headers = %{ $response->{_headers} };
  my $ro = {
	    'headers' => \%headers,
	    'content' => $response->decoded_content,
	    'code'    => $response->code,
	   };
  return $ro;
}

1;
