#!/usr/local/bin/perl
#
# Name:
#	cgi-app-two.cgi.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html.

# If you have access to Apache's httpd.conf
# you can add something like:
# PerlSetEnv INSTALL=/home/rons/cgi-app
# and then here you can try:
#use lib "$ENV{'INSTALL'}/lib";

use lib '/web/lib';
use strict;
use warnings;

use CGI::Application::Demo::Two;

# -----------------------------------------------

delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'PATH', 'SHELL'}; # For security.

CGI::Application::Demo::Two -> new() -> run();
