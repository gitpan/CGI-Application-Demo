package CGI::Application::Demo::Faculty;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

use base 'CGI::Application::Demo::Base';

our $VERSION = '1.00';

# --------------------------------------------------

__PACKAGE__ -> table('faculty');
__PACKAGE__ -> columns(All => qw/faculty_id faculty_name/);
__PACKAGE__	-> sequence('faculty_seq') if (__PACKAGE__ -> db_vendor() eq 'Pg');

# --------------------------------------------------

1;
