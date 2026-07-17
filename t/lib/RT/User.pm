package RT::User;

use strict;
use warnings;

my %_users;
my %_rights;
my $_set_password_result = { ok => 1, msg => '' };

sub _reset {
    %_users   = ();
    %_rights  = ();
    $_set_password_result = { ok => 1, msg => '' };
    return;
}

sub _add_user {
    my %args = @_;
    $_users{ $args{id} } = {
        id   => $args{id},
        Name => $args{Name},
    };
    return;
}

sub _grant_right {
    my %args = @_;
    $_rights{ $args{principal_id} }{ $args{right} } = 1;
    return;
}

sub _set_password_result {
    $_set_password_result = shift;
    return;
}

sub new {
    my $class = shift;
    return bless { _id => undef, _name => undef }, $class;
}

sub Load {
    my $self = shift;
    my $id   = shift;

    if ( $_users{$id} ) {
        $self->{_id}   = $_users{$id}{id};
        $self->{_name} = $_users{$id}{Name};
    }
    elsif ( !$id ) {
        $self->{_id} = undef;
    }
    else {
        for my $user ( values %_users ) {
            if ( $user->{Name} eq $id ) {
                $self->{_id}   = $user->{id};
                $self->{_name} = $user->{Name};
                last;
            }
        }
    }

    return;
}

sub id {
    my $self = shift;
    return $self->{_id};
}

sub Name {
    my $self = shift;
    return $self->{_name};
}

sub HasRight {
    my $self  = shift;
    my %args  = @_;
    my $right = $args{Right};
    my $obj   = $args{Object};

    return 0 unless $obj && $obj->can('id');
    return 0 unless $obj->id;
    return exists $_rights{ $obj->id }{$right} ? 1 : 0;
}

sub SetPassword {
    my $self     = shift;
    my $password = shift;

    if ( $_set_password_result->{ok} ) {
        return ( 1, 'Password set successfully' );
    }
    else {
        return ( 0, $_set_password_result->{msg} );
    }
}

1;
