#!/usr/local/bin/perl
#
# Name:
#	drop.pl.

use lib "$ENV{'INSTALL'}/lib";
use strict;
use warnings;

use CGI::Application::Demo::Create;

# -----------------------------------------------

CGI::Application::Demo::Create -> new
(
	config_file_name => "$ENV{'ASSETS'}/conf/cgi-app-demo/cgi-app-demo.conf"
) -> drop_all_tables();

