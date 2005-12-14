#!/usr/local/bin/perl
#
# Name:
#	cgi-app-lib.cgi.
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

use CGI qw/fatalsToBrowser/;

# ---------------------------

my($q)			= CGI -> new();
my($package)	= $0;

print $q -> header({type => 'text/html;charset=ISO-8859-1'}),
	$q -> start_html({title => $package}),
	$q -> h1({align => 'center'}, $package),
	'URL: ', $q -> url(), '<br />',
	'Path info: ', $q -> path_info(), '<br />',
	"CGI V: $CGI::VERSION<br />",
	$q -> end_html();

