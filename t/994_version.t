use strict;
use warnings;

use FindBin    ();
use File::Find ();
use File::Spec ();
use Test::More;

unless ( $ENV{RELEASE_TEST} ) {
    my $msg = 'Release test. Set $ENV{RELEASE_TEST} to a true value to run.';
    plan( skip_all => $msg );
}

my $dir = $FindBin::RealBin;

my ( $ret, $msg ) = read_file( $dir . '/../Changes' );
if ( !$ret ) {
    BAIL_OUT "$msg";
}

my @changes_versions;
foreach my $line ( split /\n/, $ret ) {
    if ( $line =~ /^(\d+\.\d+)\s+\d{4}/ ) {
        push @changes_versions, $1;
    }
}

my $latest_version = $changes_versions[0];
if ( $latest_version ) {
    Test::More::note( "latest version in Changes: $latest_version" );
}
else {
    BAIL_OUT "unable to read the latest version from Changes";
}

my @files = find_all_files();
subtest 'all file versions match latest version in Changes' => sub {
    plan tests => scalar @files;

    foreach my $file ( @files ) {
        my ( $ret, $msg ) = read_file( $dir . '/' . $file );
        if ( !$ret ) {
            BAIL_OUT "$msg";
        }

        my $file_version = '';
        if ( $ret =~ /VERSION\s+=\s+'(\d+\.\d+)'/ ) {
            $file_version = $1;
        }

        if ( !$file_version ) {
            pass( "$file (no VERSION, skipped)" );
        }
        else {
            is( $file_version, $latest_version, $file );
        }
    }
};

done_testing();

sub read_file {
    my $file_path = shift;

    if ( !$file_path ) {
        return ( 0, 'file_path is required' );
    }

    my $file_contents;
    open( my $fh, '<', $file_path )
        or return ( 0, "open $file_path: $!" );
    while ( my $line = <$fh> ) {
        $file_contents .= $line;
    }
    close($fh);

    return $file_contents;
}

sub find_all_files {
    my @modules;
    File::Find::find(
        sub {
            my $file = $File::Find::name;
            return unless $file =~ /\.pm$/;

            my $rel_path = File::Spec->abs2rel( $file, $dir . '/..' );
            return if $rel_path =~ /^inc/;
            return if $rel_path =~ /^t/;

            push( @modules, File::Spec->abs2rel( $file, $dir ) );
        },
        $dir . '/../',
    );

    return @modules;
}
