package CGI::Application::Demo::LogDispatchDBI;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

use base qw/Log::Dispatch::DBI CGI::Application::Demo::Base/;

our $VERSION = '1.01';

# --------------------------------------------------

sub create_statement
{
	my($self) 	= @_;
	my($vendor) = $self -> db_vendor();
	my($sql)	= $vendor eq 'Oracle'
		? "insert into $$self{'table'} (id, lvl, message, timestamp) values (log_seq.nextval, ?, ?, now() )"
		: "insert into $$self{'table'} (lvl, message, timestamp) values (?, ?, now() )"; # MySQL, Postgres.

	return $$self{'dbh'} -> prepare($sql);

}	# End of create_statement.

# --------------------------------------------------

sub log_message
{
	my($self, %param) = @_;

	$$self{'sth'} -> execute(@param{qw/level message/});

}	# End of log_message.

# --------------------------------------------------

1;
