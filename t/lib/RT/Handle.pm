package RT::Handle;

use strict;
use warnings;

sub cmp_version {
    my $caller = caller();
    my ($a, $b);
    {
        no strict 'refs';
        $a = ${$caller . '::a'};
        $b = ${$caller . '::b'};
    }

    unless (defined $a && defined $b) {
        ($a, $b) = @_;
    }

    my @a = split /\./, $a;
    my @b = split /\./, $b;
    for my $i ( 0 .. 2 ) {
        return $a[$i] <=> $b[$i] if $a[$i] != $b[$i];
    }
    return 0;
}

1;
