package RT::REST2::Resource;

use strict;
use warnings;
use Moose;
use namespace::autoclean;

has 'current_user' => (
    is       => 'ro',
    isa      => 'Object',
    required => 0,
    default  => sub { RT::User->new() },
);

has 'request' => (
    is       => 'ro',
    isa      => 'Object',
    required => 0,
    default  => sub { RT::REST2::Resource::Request->new() },
);

has 'response' => (
    is       => 'ro',
    isa      => 'Object',
    required => 0,
    default  => sub { RT::REST2::Resource::Response->new() },
);

__PACKAGE__->meta->make_immutable;

package RT::REST2::Resource::Request;

sub new {
    my $class = shift;
    my %args  = @_;
    return bless { content => $args{content} || '' }, $class;
}

sub content {
    my $self = shift;
    if (@_) {
        $self->{content} = shift;
    }
    return $self->{content};
}

sub method {
    my $self = shift;
    if (@_) {
        $self->{method} = shift;
    }
    return $self->{method} || 'GET';
}

sub uri {
    my $self = shift;
    if (@_) {
        $self->{uri} = shift;
    }
    return $self->{uri} || '';
}

package RT::REST2::Resource::Response;

sub new {
    my $class = shift;
    return bless {
        status         => 200,
        content_type   => '',
        content_length => 0,
        body           => '',
    }, $class;
}

sub status {
    my $self = shift;
    if (@_) {
        $self->{status} = shift;
    }
    return $self->{status};
}

sub content_type {
    my $self = shift;
    if (@_) {
        $self->{content_type} = shift;
    }
    return $self->{content_type};
}

sub content_length {
    my $self = shift;
    if (@_) {
        $self->{content_length} = shift;
    }
    return $self->{content_length};
}

sub body {
    my $self = shift;
    if (@_) {
        $self->{body} = shift;
    }
    return $self->{body};
}

1;
