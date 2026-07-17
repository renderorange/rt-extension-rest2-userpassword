package RT;

use strict;
use warnings;

our $VERSION = '6.0.0';
our $System;

sub InitSystem {
    require RT::System;
    $System = RT::System->new();
    return $System;
}

sub System {
    return $System;
}

1;
