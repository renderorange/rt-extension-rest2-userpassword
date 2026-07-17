use lib '.';
use inc::Module::Install;

RTx 'RT-Extension-REST2-UserPassword';
repository 'https://github.com/renderorange/rt-extension-rest2-userpassword';
license 'gpl_2';
all_from 'lib/RT/Extension/REST2/UserPassword.pm';
bugtracker 'https://github.com/renderorange/rt-extension-rest2-userpassword/issues';

requires_rt '6.0.0';
rt_too_new '6.2.0';

&WriteAll;
