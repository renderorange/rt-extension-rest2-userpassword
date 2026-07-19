package RT::REST2::Resource::UserPassword;

use strict;
use warnings;

use English qw(-no_match_vars);
use Moose;
use namespace::autoclean;
use JSON ();

extends 'RT::REST2::Resource';

has 'user_id' => (
    is       => 'ro',
    isa      => 'Maybe[Str]',
    required => 1,
);

sub dispatch_rules {
    return Path::Dispatcher::Rule::Regex->new(
        regex => qr{^/user/([^/]+)/password/?$},
        block => sub {
            my ($match) = @_;
            return { user_id => $match->pos(1) };
        },
    );
}

sub forbidden {
    my $self = shift;

    if (!$self->current_user || !$self->current_user->id) {
        return 1;
    }

    if (
        $self->current_user->HasRight(
            Right  => 'AdminUsers',
            Object => RT->System,
        )
    ) {
        return 0;
    }

    my $target = RT::User->new($self->current_user);
    $target->Load($self->user_id);
    if ($target->id && $target->id == $self->current_user->id) {
        return 0;
    }

    return 1;
}

sub resource_exists {
    my $self = shift;
    my $user = RT::User->new($self->current_user);
    $user->Load($self->user_id);
    return $user->id ? 1 : 0;
}

sub allowed_methods {
    return [qw(PUT)];
}

sub content_types_provided {
    return [ { 'application/json' => 'to_json' } ];
}

sub content_types_accepted {
    return [ { 'application/json' => 'from_json' } ];
}

sub to_json {
    my $self = shift;
    my $user = RT::User->new($self->current_user);
    $user->Load($self->user_id);

    if (!$user->id) {
        return $self->_error(404, "User not found");
    }

    return JSON::encode_json(
        {
            message => "Password resource available",
            user    => $user->Name,
        }
    );
}

sub from_json {
    my $self    = shift;
    my $content = $self->request->content;

    my $params = eval { return JSON::decode_json($content) };
    if ($EVAL_ERROR) {
        return $self->_error(400, "Invalid JSON");
    }

    my $password = $params->{Password};

    if (!defined $password || !length $password) {
        return $self->_error(400, "Password is required");
    }

    my $user = RT::User->new($self->current_user);
    $user->Load($self->user_id);

    if (!$user->id) {
        return $self->_error(404, "User not found");
    }

    my ($ok, $msg) = $user->SetPassword($password);

    if ($ok) {
        my $body = JSON::encode_json({ message => "Password updated" });
        $self->response->content_type("application/json; charset=utf-8");
        $self->response->content_length(length $body);
        $self->response->body($body);
        return;
    }
    else {
        return $self->_error(400, $msg || "Failed to update password");
    }
}

sub _error {
    my ($self, $code, $message) = @_;
    my $body = JSON::encode_json({ message => $message });
    $self->response->status($code);
    $self->response->content_type("application/json; charset=utf-8");
    $self->response->content_length(length $body);
    $self->response->body($body);
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

RT::REST2::Resource::UserPassword - REST2 endpoint for user password updates

=head1 DESCRIPTION

Provides a REST2 resource for updating user passwords via C<PUT /user/:id/password>.

=head1 METHODS

=head2 dispatch_rules

Returns the path dispatch rules matching C</user/:id/password>.

=head2 forbidden

Returns 1 if the current user lacks permission, 0 if permitted.
Allowed when the user has C<AdminUsers> right or is updating their own password.

=head2 resource_exists

Returns 1 if the target user exists, 0 otherwise.

=head2 allowed_methods

Returns C<['PUT']>.

=head2 content_types_provided

Returns C<application/json>.

=head2 content_types_accepted

Returns C<application/json>.

=head2 to_json

Returns a JSON response indicating the password resource is available.

=head2 from_json

Parses the JSON request body and updates the target user's password.

=cut
