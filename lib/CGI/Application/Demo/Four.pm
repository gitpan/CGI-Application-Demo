package CGI::Application::Demo::Four;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	http://savage.net.au/index.html

use base 'CGI::Application';
use strict;
use warnings;

require 5.005_62;

use CGI::Application::Plugin::Config::Context;
use CGI::Simple;
use DBI;

our $VERSION = '1.03';

# -----------------------------------------------

sub cgiapp_get_query
{
	my($self) = @_;

	return CGI::Simple -> new();

}	# End of cgiapp_get_query.

# -----------------------------------------------

sub cgiapp_init
{
	my($self) = @_;

	# Warning: When running a CGI script from the command line, omit the 'nfs/' everywhere.

	my($config_file) =
		$^O eq 'MSWin32'
		? '/apache2/conf/cgi-app-demo/cgi-app-four.conf'
		: '/web/assets/conf/cgi-app-demo/cgi-app-four.conf';

	$self -> conf() -> init(file => $config_file);

	my $config = $self -> conf() -> context();

	$self -> param(config => $config);
	$self -> param(dbh => DBI -> connect($$config{'dsn'}, $$config{'username'}, $$config{'password'}) );
	$self -> param(tmpl_path => $$config{'tmpl_path'});

}	# End of cgiapp_init.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start);
	$self -> tmpl_path($self -> param('tmpl_path') );

}	# End of setup.

# -----------------------------------------------

sub start
{
	my($self)		= shift;
	my($config)		= $self -> param('config');
	my($template)	= $self -> load_tmpl($$config{'tmpl_name'});
	my(@content)	=
	(
		'Time: ' . scalar localtime(),
		'URL: ' . $self -> query() -> url(),
		'PathInfo: ' . $self -> query() -> path_info(),
		"CGI::Application::Plugin::Config::Context: V $CGI::Application::Plugin::Config::Context::VERSION",
		"CGI::Simple V $CGI::Simple::VERSION",
		"DBI V $DBI::VERSION",
		'Template name: ' . $$config{'tmpl_name'},
		'Template path: ' . $self -> param('tmpl_path'),
		'dbh: ' . $self -> param('dbh'),
	);

	# Test DBI.

	my($sql) = 'select faculty_id, faculty_name from faculty';
	my($sth) = $self -> param('dbh') -> prepare($sql);

	$sth -> execute();

	my($data);

	while ($data = $sth -> fetch() )
	{
		push @content, qq|<span class="$$config{'css_class'}">$$data[0]: $$data[1]</span>|;
	}

	$template -> param(css_url => $$config{'css_url'});
	$template -> param(li_loop => [map{ {item => $_} } @content]);
	$template -> param(title => __PACKAGE__);

	$self -> param('dbh') -> disconnect();

	return $template -> output();

}	# End of start.

# -----------------------------------------------

1;
