package CGI::Application::Demo::Create;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

use Carp;
use Config::General;
use DBI;
use FindBin::Real;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Application::Demo::Create ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.00';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_config_file_name => '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}

}	# End of encapsulated class data.

# --------------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	$self -> create_faculty_table();
	$self -> create_log_table();
	$self -> create_sessions_table();

}	# End of create_all_tables.

# --------------------------------------------------

sub create_faculty_table
{
	my($self	)		= @_;
	my($table_name)		= 'faculty';
	my($primary_key)	= $self -> describe_primary_key($table_name);

	$self -> drop_table($table_name);
	$$self{'_dbh'} -> do("create sequence ${table_name}_seq") if ($$self{'_db_vendor'} ne 'mysql');
	$$self{'_dbh'} -> do(<<SQL);
create table faculty
(
faculty_id $primary_key,
faculty_name varchar(255) not null
)
SQL

}	# End of create_faculty_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)			= @_;
	my($table_name)		= 'log';
	my($primary_key)	= $self -> describe_primary_key($table_name);

	$self -> drop_table($table_name);
	$$self{'_dbh'} -> do("create sequence ${table_name}_seq") if ($$self{'_db_vendor'} ne 'mysql');
	$$self{'_dbh'} -> do(<<SQL);
create table log
(
id $primary_key,
timestamp timestamp,
lvl varchar(9),
message varchar(255)
)
SQL

}	# End of create_log_table.

# --------------------------------------------------
# Note: The sessions table is a special case.

sub create_sessions_table
{
	my($self) 		= @_;
	my($table_name)	= 'sessions';

	$self -> drop_table($table_name);
	$$self{'_dbh'} -> do(<<SQL);
create table sessions
(
id char(32) not null primary key,
a_session text not null
)
SQL

}	# End of create_sessions_table.

# --------------------------------------------------

sub describe_primary_key
{
	my($self, $table_name) = @_;

	# MySQL || Postgres.
	# Postgres via ODBC under Windows doesn't work,
	# in that "default nextval('${table_name}_seq')" is ignored.

	($$self{'_db_vendor'} eq 'mysql')
	? 'integer auto_increment not null primary key'
	: "integer primary key default nextval('${table_name}_seq')";

}	# End of describe_primary_key.

# --------------------------------------------------

sub DESTROY
{
	my($self) = @_;

	$$self{'_dbh'} -> disconnect();

}	# End of DESTROY.

# --------------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	$self -> drop_table('faculty');
	$self -> drop_table('log');
	$self -> drop_table('sessions');

}	# End of drop_all_tables.

# --------------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	if ($$self{'_db_vendor'} eq 'mysql')
	{
	}
	else # Postgres.
	{
		eval{$$self{'_dbh'} -> do("drop index ${table_name}_pkey")};
		eval{$$self{'_dbh'} -> do("drop sequence ${table_name}_seq")};
	}

	eval{$$self{'_dbh'} -> do("drop table $table_name")};

}	# End fo drop_table.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	croak(__PACKAGE__ . ". You must supply a value for 'config_file_name'") if (! $$self{'_config_file_name'});

	my(%config)				= Config::General -> new($$self{'_config_file_name'}) -> getall();
	my($config)				= $config{'Location'}{'/cgi-bin/cgi-app-demo/cgi-app-demo.cgi'};
	($$self{'_db_vendor'})	= $$config{'dsn'} =~ /[^:]+:([^:]+):/;
	$$self{'_dbh'}			= DBI -> connect
	(
		$$config{'dsn'},
		$$config{'username'},
		$$config{'password'},
		$$config{'dsn_attribute'}
	);

	return $self;

}	# End of new.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> populate_faculty_table();

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_faculty_table
{
	my($self)	= @_;
	my($data)	= $self -> read_file('faculty.txt');
	my($sth)	= $$self{'_dbh'} -> prepare('insert into faculty (faculty_name) values (?)');

	$sth -> execute($_) for @$data;
	$sth -> finish();

}	# End of populate_faculty_table.

# --------------------------------------------------
# Assumed directory structure:
#	./data/faculty.txt
#	./scripts/populate.pl

sub read_file
{
	my($self, $input_file_name)	= @_;
	$input_file_name			= FindBin::Real::Bin() . "/../data/$input_file_name";

	open(INX, $input_file_name) || Carp::croak("Can't open($input_file_name): $!");
	my(@line) = grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} <INX>;
	close INX;
	chomp @line;

	\@line;

}	# End of read_file.

# -----------------------------------------------

1;
