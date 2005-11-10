#!/usr/bin/perl

use strict;
use warnings;

use Config::General;

# -----------------------------------------------

my($config_file)	= "$ENV{'CONFIG'}/cgi-app-demo.conf";
my(%config)			= Config::General -> new($config_file) -> getall();
my($config)			= $config{'Location'}{'/cgi-bin/cgi-app-demo/cgi-app-demo.cgi'};

print map{"$_ => $$config{$_}. \n"} sort keys %$config;
print "\n";
print "dsn_attribute: \n";
print map{"$_ => $$config{'dsn_attribute'}{$_}. \n"} sort keys %{$$config{'dsn_attribute'} };
