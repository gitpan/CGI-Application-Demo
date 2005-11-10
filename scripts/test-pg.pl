#!/usr/bin/perl
#
# Name:
#	test-pg.pl.
#
# Purpose:
#	Test DBIx::SQLEngine on db test's tables.
#	Output to HTML.

use lib "$ENV{'INSTALL'}/lib";
use strict;
use warnings;

use DBI;

# -----------------------------------------------

my($dbh) = DBI -> connect
(
	'dbi:Pg:dbname=cgi_app_demo', 'postgres', '',
	{
		AutoCommit			=> 1,
		PrintError			=> 0,
		RaiseError			=> 1,
		ShowErrorStatement	=> 1,
	}
);
my($table_name) = 't';

eval{$dbh -> do("drop table $table_name")};
$dbh -> do("create sequence ${table_name}_id_seq");
$dbh -> do("create table $table_name (id integer primary key default nextval('t_id_seq'), d varchar(255) )");

my($value) = 'abc';

$dbh -> do("insert into $table_name (d) values ($value)");

my($id) = $dbh -> last_insert_id(undef, undef, $table_name, undef);

print "Last insert id: $id. Value: $value. \n";

$value = 'xyz';

$dbh -> do("insert into $table_name (d) values ($value)");

$id = $dbh -> last_insert_id(undef, undef, $table_name, undef);

print "Last insert id: $id. Value: $value. \n";

my($sth) = $dbh -> prepare("select * from $table_name");

$sth -> execute();

my($data);

while ($data = $sth -> fetchrow_hashref() )
{
	print map{"$_ => $$data{$_}. \n"} sort keys %$data;
	print "\n";
}

$dbh -> do("drop table $table_name");
$dbh -> do("drop sequence ${table_name}_id_seq");

$dbh -> disconnect();
