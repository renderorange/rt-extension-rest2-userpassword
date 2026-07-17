package RT::System;

use strict;
use warnings;

sub new {
    my $class = shift;
    return bless { _id => 1 }, $class;
}

sub id {
    my $self = shift;
    return $self->{_id};
}

1;
