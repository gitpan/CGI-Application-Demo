package CGI::Application::Demo::Base;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

use base 'Class::DBI'; # Amazing. Don't need Class::DBI::Pg nor Class::DBI::Oracle!

use Config::General;
use FindBin::Real;

my($config);

our $VERSION = '1.01';

# --------------------------------------------------

sub dbh
{
	my($self) = @_;

	__PACKAGE__ -> db_Main();

}	# End of dbh.

# --------------------------------------------------

sub db_vendor
{
	my($self)	= @_;
	my($vendor)	= $$config{'dsn'} =~ /[^:]+:([^:]+):/;

	$vendor;

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

	$id;

}	# End of last_insert_id.

# --------------------------------------------------
# Scripts using this will be CGI scripts.
# See also Demo.pm's sub cgiapp_init().
# Assumed directory structure:
#	./cgi-bin/cgi-app-demo/cgi-app-demo.cgi
#	./conf/cgi-app-demo/cgi-app-demo.conf

my($config_file)	= FindBin::Real::Bin() . '/../../conf/cgi-app-demo/cgi-app-demo.conf';
my(%config)			= Config::General -> new($config_file) -> getall();
$config				= $config{'Location'}{'/cgi-bin/cgi-app-demo/cgi-app-demo.cgi'};

__PACKAGE__ -> set_db('Main', $$config{'dsn'}, $$config{'username'}, $$config{'password'}, $$config{'dsn_attribute'});

# --------------------------------------------------

1;
