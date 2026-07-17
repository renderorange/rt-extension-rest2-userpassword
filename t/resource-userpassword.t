use strict;
use warnings;

use FindBin ();
use lib "$FindBin::RealBin/lib", "$FindBin::RealBin/../lib";

use Test::More;
use JSON ();

use RT;
use RT::User;
use Path::Dispatcher::Rule::Regex;
use RT::REST2::Resource::UserPassword;

my $system = RT->InitSystem();

my $admin_id    = 1;
my $regular_id  = 2;
my $other_id    = 3;
my $admin_name   = 'admin';
my $regular_name = 'regularuser';
my $other_name   = 'otheruser';

sub setup_users {
    RT::User::_reset();

    RT::User::_add_user( id => $admin_id,   Name => $admin_name );
    RT::User::_add_user( id => $regular_id, Name => $regular_name );
    RT::User::_add_user( id => $other_id,   Name => $other_name );

    return;
}

sub make_current_user {
    my $id = shift;
    my $user = RT::User->new();
    $user->Load($id);
    return $user;
}

sub make_resource {
    my %args = @_;

    my $current_user = $args{current_user} || RT::User->new();

    my $request = RT::REST2::Resource::Request->new(
        content => $args{content} || '',
    );

    my $response = RT::REST2::Resource::Response->new();

    return RT::REST2::Resource::UserPassword->new(
        user_id      => $args{user_id}      || '',
        current_user => $current_user,
        request      => $request,
        response     => $response,
    );
}

DISPATCH_RULES: {
    note( 'dispatch_rules' );

    my @rules = RT::REST2::Resource::UserPassword->dispatch_rules();
    is( scalar @rules, 1, 'dispatch_rules returns one rule' );

    my $rule  = $rules[0];
    my $regex = $rule->regex;

    ok( '/user/123/password'  =~ $regex, 'matches /user/123/password' );
    is( $1, '123', 'captures user_id from /user/123/password' );

    ok( '/user/456/password/' =~ $regex, 'matches /user/456/password/ (trailing slash)' );
    is( $1, '456', 'captures user_id from /user/456/password/' );

    ok( '/user/abc/password'  =~ $regex, 'matches /user/abc/password' );
    is( $1, 'abc', 'captures user_id from /user/abc/password' );

    ok( '/user/123/password' !~ $regex || '/user/123' !~ $regex, 'does not match /user/123' );
    ok( '/user/123'          !~ $regex, 'does not match /user/123' );
    ok( '/user/123/other'    !~ $regex, 'does not match /user/123/other' );
    ok( '/users/123/password' !~ $regex, 'does not match /users/123/password' );
    ok( '/'                  !~ $regex, 'does not match /' );
}

FORBIDDEN: {
    note( 'forbidden' );

    setup_users();

    subtest 'unauthenticated user is denied' => sub {
        my $resource = make_resource(
            user_id      => $regular_id,
            current_user => RT::User->new(),
        );
        is( $resource->forbidden(), 1, 'unauthenticated user returns forbidden' );
    };

    subtest 'user without AdminUsers right is denied for other user' => sub {
        my $resource = make_resource(
            user_id      => $other_id,
            current_user => make_current_user($regular_id),
        );
        is( $resource->forbidden(), 1, 'regular user updating other password returns forbidden' );
    };

    subtest 'user with AdminUsers right is allowed' => sub {
        RT::User::_grant_right( principal_id => $system->id, right => 'AdminUsers' );

        my $resource = make_resource(
            user_id      => $regular_id,
            current_user => make_current_user($admin_id),
        );
        is( $resource->forbidden(), 0, 'admin user returns not forbidden' );

        RT::User::_reset();
        setup_users();
    };

    subtest 'user updating own password is allowed' => sub {
        my $resource = make_resource(
            user_id      => $regular_id,
            current_user => make_current_user($regular_id),
        );
        is( $resource->forbidden(), 0, 'user updating own password returns not forbidden' );
    };
}

RESOURCE_EXISTS: {
    note( 'resource_exists' );

    setup_users();

    subtest 'existing user returns true' => sub {
        my $resource = make_resource(
            user_id      => $regular_id,
            current_user => make_current_user($admin_id),
        );
        is( $resource->resource_exists(), 1, 'existing user returns true' );
    };

    subtest 'non-existent user returns false' => sub {
        my $resource = make_resource(
            user_id      => 999,
            current_user => make_current_user($admin_id),
        );
        is( $resource->resource_exists(), 0, 'non-existent user returns false' );
    };
}

ALLOWED_METHODS: {
    note( 'allowed_methods' );

    my $resource = make_resource( user_id => $regular_id );
    my $methods = $resource->allowed_methods();
    is_deeply( $methods, ['PUT'], 'only PUT is allowed' );
}

CONTENT_TYPES: {
    note( 'content_types_provided and content_types_accepted' );

    my $resource = make_resource( user_id => $regular_id );

    my $provided = $resource->content_types_provided();
    is( scalar @{$provided}, 1, 'one content type provided' );
    is( $provided->[0]{'application/json'}, 'to_json', 'application/json maps to to_json' );

    my $accepted = $resource->content_types_accepted();
    is( scalar @{$accepted}, 1, 'one content type accepted' );
    is( $accepted->[0]{'application/json'}, 'from_json', 'application/json maps to from_json' );
}

TO_JSON: {
    note( 'to_json' );

    setup_users();

    subtest 'existing user returns user info' => sub {
        my $resource = make_resource(
            user_id      => $regular_id,
            current_user => make_current_user($admin_id),
        );

        my $json = $resource->to_json();
        my $data = JSON::decode_json($json);
        is( $data->{message}, 'Password resource available', 'message is correct' );
        is( $data->{user}, $regular_name, 'user name is correct' );
    };

    subtest 'non-existent user returns 404' => sub {
        my $resource = make_resource(
            user_id      => 999,
            current_user => make_current_user($admin_id),
        );

        $resource->to_json();
        is( $resource->response->status(), 404, 'status is 404' );

        my $data = JSON::decode_json( $resource->response->body() );
        is( $data->{message}, 'User not found', 'error message is correct' );
    };
}

FROM_JSON_INVALID_JSON: {
    note( 'from_json - invalid JSON' );

    setup_users();

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => 'not json',
    );

    $resource->from_json();
    is( $resource->response->status(), 400, 'status is 400' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Invalid JSON', 'error message is correct' );
}

FROM_JSON_MISSING_PASSWORD: {
    note( 'from_json - missing Password field' );

    setup_users();

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ NotPassword => 'test' }),
    );

    $resource->from_json();
    is( $resource->response->status(), 400, 'status is 400' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Password is required', 'error message is correct' );
}

FROM_JSON_EMPTY_PASSWORD: {
    note( 'from_json - empty Password field' );

    setup_users();

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ Password => '' }),
    );

    $resource->from_json();
    is( $resource->response->status(), 400, 'status is 400' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Password is required', 'error message is correct' );
}

FROM_JSON_USER_NOT_FOUND: {
    note( 'from_json - user not found' );

    setup_users();

    my $resource = make_resource(
        user_id      => 999,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ Password => 'newpassword' }),
    );

    $resource->from_json();
    is( $resource->response->status(), 404, 'status is 404' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'User not found', 'error message is correct' );
}

FROM_JSON_SUCCESS: {
    note( 'from_json - successful password update' );

    setup_users();

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ Password => 'newpassword' }),
    );

    $resource->from_json();

    is( $resource->response->content_type(), 'application/json; charset=utf-8', 'content type is correct' );
    ok( $resource->response->content_length() > 0, 'content length is set' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Password updated', 'success message is correct' );
}

FROM_JSON_SET_PASSWORD_FAILURE: {
    note( 'from_json - SetPassword failure' );

    setup_users();
    RT::User::_set_password_result( { ok => 0, msg => 'Password too short' } );

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ Password => 'abc' }),
    );

    $resource->from_json();
    is( $resource->response->status(), 400, 'status is 400' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Password too short', 'error message from SetPassword is returned' );
}

FROM_JSON_SET_PASSWORD_FAILURE_NO_MSG: {
    note( 'from_json - SetPassword failure with no message' );

    setup_users();
    RT::User::_set_password_result( { ok => 0, msg => '' } );

    my $resource = make_resource(
        user_id      => $regular_id,
        current_user => make_current_user($admin_id),
        content      => JSON::encode_json({ Password => 'abc' }),
    );

    $resource->from_json();
    is( $resource->response->status(), 400, 'status is 400' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'Failed to update password', 'default error message is returned' );
}

ERROR_METHOD: {
    note( '_error method' );

    my $resource = make_resource( user_id => $regular_id );

    $resource->_error( 418, 'I am a teapot' );
    is( $resource->response->status(), 418, 'status is set' );
    is( $resource->response->content_type(), 'application/json; charset=utf-8', 'content type is set' );
    ok( $resource->response->content_length() > 0, 'content length is set' );

    my $data = JSON::decode_json( $resource->response->body() );
    is( $data->{message}, 'I am a teapot', 'message is correct' );
}

done_testing();
