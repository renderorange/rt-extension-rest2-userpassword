use strict;
use warnings;

use FindBin;
use Test::More;

unless ( $ENV{AUTHOR_TEST} ) {
    my $msg = 'Author test. Set $ENV{AUTHOR_TEST} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::PerlTidy; };

if ($@) {
    my $msg = 'Test::PerlTidy required to criticise code';
    plan( skip_all => $msg );
}

Test::PerlTidy::run_tests(
    path       => "$FindBin::RealBin/../lib",
    perltidyrc => "$FindBin::RealBin/perltidyrc",
);
