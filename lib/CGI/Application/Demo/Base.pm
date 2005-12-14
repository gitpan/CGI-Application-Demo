package CGI::Application::Demo::Base;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use base 'Class::DBI'; # Amazing. For MySQL, Oracle and Postgres, use Class::DBI.
use strict;
use warnings;

use Config::General;

my(%config);

our $VERSION = '1.02';

# --------------------------------------------------

sub dbh
{
	my($self) = @_;

	return __PACKAGE__ -> db_Main();

}	# End of dbh.

# --------------------------------------------------

sub db_vendor
{
	my($self)	= @_;
	my($vendor)	= $config{'dsn'} =~ /^dbi:(\w+):/i;

	return $vendor;

}	# End of db_vendor.

# --------------------------------------------------

sub last_insert_id
{
	my($self, $table_name) = @_;

	my($id);

	if ($self -> db_vendor() =~ /(?:mysql|Pg)/)
	{
		$id = $self -> dbh() -> last_insert_id(undef, undef, $table_name, undef);
	}
	else # Oracle.
	{
		my($sth) = $self -> dbh() -> prepare("select ${table_name}_seq.currval from dual");

		$sth -> execute();

		$id = $sth -> fetch();

		$sth -> finish();

		$id = $$id[0];
	}

	return $id;

}	# End of last_insert_id.

# --------------------------------------------------
# Scripts using this will be CGI scripts but not command line scripts.

my($config_file) =
	$^O eq 'MSWin32'
	? '/apache2/conf/cgi-app-demo'
	: '/web/assets/conf/cgi-app-demo';
$config_file	.= '/cgi-app-five.conf';
%config			= Config::General -> new($config_file) -> getall();

__PACKAGE__ -> set_db('Main', $config{'dsn'}, $config{'username'}, $config{'password'}, $config{'dsn_attribute'});

# --------------------------------------------------

1;
