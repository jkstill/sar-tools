# call with perl -n -i

use warnings;
use strict;


if ($. == 1) { print; next; }
next if /LINUX-RESTART|#\s*hostname,interval/;
print;
