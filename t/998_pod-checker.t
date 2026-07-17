use strict;
use warnings;

use FindBin;
use Test::More;

unless ( $ENV{AUTHOR_TEST} ) {
    my $msg = 'Author test. Set $ENV{AUTHOR_TEST} to a true value to run.';
    plan( skip_all => $msg );
}

eval { require Test::Pod; };

if ($@) {
    my $msg = 'Test::Pod required to criticise code';
    plan( skip_all => $msg );
}

Test::Pod::all_pod_files_ok( Test::Pod::all_pod_files("$FindBin::RealBin/../lib") );
