package RT::Handle;

use strict;
use warnings;

sub cmp_version {
    my ( $a, $b ) = @_;
    my @a = split /\./, $a;
    my @b = split /\./, $b;
    for my $i ( 0 .. 2 ) {
        return $a[$i] <=> $b[$i] if $a[$i] != $b[$i];
    }
    return 0;
}

1;
