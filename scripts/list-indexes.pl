#!/usr/bin/perl
#
# Name:
#	list-indexes.pl
#
# Purpose:
#	List the indexes on a table.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#
# Notes:
#	Set DBI_DSN=dbi:mysql:name-of-db
#	or  DBI_DSN=dbi:Pg:dbname=name-of-db
#	Set DBI_USER=a-name
#	Set DBI_PASS=a-password

use lib '/home/mids/mids-vhost/cgi-app/lib';
use strict;
use warnings;

use DBI;

# -----------------------------------------------

eval{require DBD::mysql};
eval{require DBD::Pg};

print "DBI V $DBI::VERSION. \n";
print "DBD::mysql V ", ($DBD::mysql::VERSION || 'N/A'), ". \n";
print "DBD::Pg V ", ($DBD::Pg::VERSION || 'N/A'), ". \n";
print "\n";

my($dbh)	= DBI -> connect();
my($sth)	= $dbh -> table_info(undef, undef, '%', 'TABLE');
my($info)	= $sth -> fetchall_arrayref({});

my($table, @table_name, $s);

for $table (@$info)
{
	next if ($$table{'TABLE_NAME'} =~ /^(pg_|sql_)/);

	push @table_name, $$table{'TABLE_NAME'};

	print map{$s = $$table{$_} ? $$table{$_} : 'NULL'; "$_ => $s. \n"} sort keys %$table;
	print "\n";
}

my($column);

for my $table_name (sort @table_name)
{
	print "Table: '$table_name'. \n";
	print "\n";
	print "Primary key information: \n";
	print "\n";

	$sth = $dbh -> primary_key_info(undef, undef, $table_name);

	if (defined $sth)
	{
		$info = $sth -> fetchall_arrayref({});

		for $column (@$info)
		{
			print map{$s = $$column{$_} ? $$column{$_} : 'NULL'; "$_ => $s. \n"} sort keys %$column;
		}
	}

	print "\n";
	print "Foreign key information: \n";
	print "\n";

	for my $foreign_table (sort grep{! /^$table_name$/} @table_name)
	{
		$sth = $dbh -> foreign_key_info(undef, undef, $table_name, undef, undef, $foreign_table);

		if (defined $sth)
		{
			$info = $sth -> fetchall_arrayref({});

			for $column (@$info)
			{
				print "Foreign table: '$foreign_table'. \n";
				print "\n";
				print map{$s = $$column{$_} ? $$column{$_} : 'NULL'; "$_ => $s. \n"} sort keys %$column;
				print "\n";
			}
		}
	}

	print '-' x 50, "\n";
}
