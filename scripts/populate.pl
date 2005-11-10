#!/usr/local/bin/perl
#
# Name:
#	populate.pl.

use lib "$ENV{'INSTALL'}/lib";
use strict;
use warnings;

use CGI::Application::Demo::Create;

# ----------------------------

CGI::Application::Demo::Create -> new
(
	config_file_name => "$ENV{'CONFIG'}/cgi-app-demo/cgi-app-demo.conf"
) -> populate_all_tables();

