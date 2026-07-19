package RT::Extension::REST2::UserPassword;

use strict;
use warnings;

our $VERSION = '1.01';

1;

__END__

=head1 NAME

RT-Extension-REST2-UserPassword - Password update endpoint for the REST2 API

=head1 DESCRIPTION

This extension adds a REST2 endpoint for updating user passwords:

    PUT /user/:id/password
    Content-Type: application/json

    {"Password": "newpassword"}

Requires AdminUsers right or updating own password.

=head1 RT VERSION

Works with RT 6.

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

=item Edit your F</opt/rt6/etc/RT_SiteConfig.pm>

Add this line:

    Plugin('RT::Extension::REST2::UserPassword');

=item Restart your webserver

=back

=head1 USAGE

=head2 Updating Passwords

To update a user's password, send a PUT request with the new password in
JSON format:

    curl -X PUT
         -H "Content-Type: application/json"
         -H "Authorization: token XX_TOKEN_XX"
         -d '{"Password": "newpassword"}'
         'https://rt.example.com/REST/2.0/user/123/password'

If successful, you'll receive:

    {"message": "Password updated"}

Requires either the AdminUsers right or updating your own password.

=head1 ENDPOINTS

=head2 PUT /user/:id/password

    PUT /user/:id/password
        update a user's password; provide JSON content

The JSON payload must include:

    Password
        The new password string. Required.

=head1 AUTHOR

Blaine Motsinger <blaine@renderorange.com>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Blaine Motsinger

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
