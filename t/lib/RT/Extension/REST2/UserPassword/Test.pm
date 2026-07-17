package RT::Extension::REST2::UserPassword::Test;

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/../tools/fake-rt/lib", "$FindBin::RealBin/../lib";

use parent 'Test::More';

sub import {
    my $class = shift;
    my %args  = @_;

    if ( $args{tests} ) {
        $class->builder->plan( tests => $args{tests} );
    }

    require RT;
    RT::InitSystem();

    require RT::User;
    require RT::REST2::Resource::UserPassword;

    Test::More->export_to_level(1);

    return;
}

sub reset_users {
    RT::User::_reset();
    return;
}

sub add_user {
    my %args = @_;
    RT::User::_add_user(%args);
    return;
}

sub grant_right {
    my %args = @_;
    RT::User::_grant_right(%args);
    return;
}

sub set_password_result {
    my $result = shift;
    RT::User::_set_password_result($result);
    return;
}

sub make_resource {
    my %args = @_;

    my $current_user = $args{current_user} || RT::User->new();

    my $request = RT::REST2::Resource::Request->new(
        content => $args{content} || '',
    );

    my $response = RT::REST2::Resource::Response->new();

    my $resource = RT::REST2::Resource::UserPassword->new(
        user_id      => $args{user_id}      || '',
        current_user => $current_user,
        request      => $request,
        response     => $response,
    );

    return $resource;
}

1;
