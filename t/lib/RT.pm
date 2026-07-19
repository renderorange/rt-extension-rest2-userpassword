package RT;

use strict;
use warnings;

our $VERSION = '6.0.0';
our $System;
our $LocalPath = '/opt/rt6/local';
our $LocalLibPath = '/opt/rt6/local/lib';
our $LocalPluginPath = '/opt/rt6/local/plugins';
our $PluginPath = '/opt/rt6/plugins';
our $BasePath = '/opt/rt6';
our $BinPath = '/opt/rt6/bin';
our $SbinPath = '/opt/rt6/sbin';
our $StaticPath = '/opt/rt6/share/static';
our $MasonDataDir = '/opt/rt6/var/mason_data';
our %CORED_PLUGINS = ();

sub InitSystem {
    require RT::System;
    $System = RT::System->new();
    return $System;
}

sub System {
    return $System;
}

sub Config { $RT::Config }

1;
