package CGI::Application::Demo;

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
use CGI::Application::Plugin::LogDispatch;
use CGI::Application::Plugin::Session;
use CGI::Simple;
use Class::DBI::Loader;

our $VERSION = '1.02';

# -----------------------------------------------

sub build_basic_pane
{
	my($self, $submit)	= @_;
	my($content)		= $self -> load_tmpl('cgi-app-basic.tmpl');
	my($count)			= $self -> session() -> param('count') || 0;

	$count++;

	$self -> session() -> param(count => $count);

	my(@tr_loop);

	for my $table (sort keys %{$self -> param('cgi_app_demo_tables')})
	{
		my($class)			= ${$self -> param('cgi_app_demo_tables')}{$table};
		my(@column)			= $self -> get_columns($class);
		my(@column_name)	= sort @{$column[2]};

		push @tr_loop,
		{
			th => 'Table',
			td => $table,
		},
		{
			th => 'Class',
			td => $class,
		},
		{
			th => 'Columns',
			td => join(', ', @column_name),
		},
		{
			# Normally, of course, you'd never put HTML inside Perl :-),
			# but for the purposes of this demo, /I/ can do it.

			th => '<hr />',
			td => '<hr />',
		};
	}

	$content -> param(count => "sub build_basic_pane() has run $count time(s)");
	$content -> param(tr_loop => \@tr_loop);
	$content -> param(commands => $self -> build_commands_output
	([
		'Refresh',
	]) );
	$content -> param(notes => $self -> build_notes_output
	([
		'Hint: Click Refresh',
		"Command: $submit",
	]) );

	return $content -> output();

}	# End of build_basic_pane.

# -----------------------------------------------

sub build_commands_output
{
	my($self, $command)		= @_;
	my($content)			= $self -> load_tmpl('cgi-app-commands.tmpl');
	my(@loop)				= ();
	my($max_column_count)	= $self -> param('columns_of_commands_option');
	my($row_count)			= int( (@$command + $max_column_count - 1) / $max_column_count);
	my($command_index)		= - 1;

	my($row, $col);

	for $row (1 .. $row_count)
	{
		my(@td_loop);

		for $col (1 .. $max_column_count)
		{
			$command_index++;

			next if ($command_index > $#$command);

			if (ref($$command[$command_index]) eq 'ARRAY')
			{
				push @td_loop, {td => $$command[$command_index][0], onClick => $$command[$command_index][1]};
			}
			else
			{
				push @td_loop, {td => $$command[$command_index]};
			}
		}

		push @loop, {col_loop => \@td_loop};
	}

	$content -> param(commands => $#$command == 0 ? 'Command' : 'Commands');
	$content -> param(row_loop => \@loop);

	return $content -> output();

}	# End of build_commands_output.

# -----------------------------------------------

sub build_notes_output
{
	my($self, $note)	= @_;
	my($content)		= $self -> load_tmpl('cgi-app-notes.tmpl');
	my(@loop)			= ();

	push @loop, {td => $_} for (@$note);

	$content -> param(note_loop => \@loop);

	return $content -> output();

}	# End of build_notes_output.

# -----------------------------------------------

sub build_options_pane
{
	my($self, $submit)	= @_;
	my($content)		= $self -> load_tmpl('cgi-app-options.tmpl');
	my(@key)			= sort keys %{${$self -> param('key')}{'option'} };

	my(@loop, $minimum, $maximum, $s);

	for (@key)
	{
		$minimum	= ${$self -> param('key')}{'option'}{$_}{'minimum'};
		$maximum	= ${$self -> param('key')}{'option'}{$_}{'maximum'};
		($s			= $_) =~ s/_option$//;
		$s			=~ tr/_/ /;
		$s			= "Number of $s ($minimum .. $maximum)";

		push @loop,
		{
			option	=> $s,
			name	=> $_,
			value	=> $self -> session() -> param($_),
		};
	}

	$content -> param(commands => $self -> build_commands_output
	([
		['Update options', q|onClick = "set('update_options')"|],
	]) );
	$content -> param(notes => $self -> build_notes_output
	([
		'DSN: ' . $self -> param('dsn'),
		"Command: $submit",
	]) );
	$content -> param(tr_loop => \@loop);

	return $content -> output();

}	# End of build_options_pane.

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
		? '/apache2/conf/cgi-app-demo/cgi-app-demo.conf'
		: '/web/assets/conf/cgi-app-demo/cgi-app-demo.conf';

	$self -> conf() -> init(file => $config_file);

	my $config = $self -> conf() -> context();

	# All this stuff is here so that we can call
	# CGI::Application::Plugin::LogDispatch's log_config, if at all,
	# in cgiapp_init (as suggested by its docs) rather than in setup.

	$self -> param(config => $config);
	$self -> param(css_url => $$config{'css_url'});
	$self -> param(dsn => $$config{'dsn'});
	$self -> param(title => $$config{'dsn'});
	$self -> param(tmpl_path => $$config{'tmpl_path'});

	# Set up the classes for each table, via the magic of Class::DBI.
	# I have used a constraint because this is a demo, and I've only
	# created one module for Class::DBI to chew on:
	# CGI::Application::Demo::Faculty.

	my($loader) = Class::DBI::Loader -> new
	(
		constraint		=> '^faculty$',
		dsn				=> $$config{'dsn'},
		user			=> $$config{'username'},
		password		=> $$config{'password'},
		options			=> $$config{'dsn_attribute'},
		namespace		=> '',
		relationships	=> 1,
	);

    $self -> setup_db_interface($loader);
	$self -> param(dbh => ${$self -> param('cgi_app_demo_classes')}[0] -> db_Main() );

	# Set up interface to logger.

	$self -> log_config
	(
		LOG_DISPATCH_MODULES =>
		[{
			dbh			=> $self -> param('dbh'),
			min_level	=> 'info',
			module		=> 'CGI::Application::Demo::LogDispatchDBI',
			name		=> 'CGI::Application::Demo::LogDispatchDBI',
		},
		]
	);

	# Set up interface to CGI::Session.

	$self -> session_config
	(
		CGI_SESSION_OPTIONS => [$$config{'session_driver'}, $self -> query(), {Handle => $self -> param('dbh')}],
		DEFAULT_EXPIRY		=> $$config{'session_timeout'},
		SEND_COOKIE			=> 0,
	);

	# Recover options from session, if possible.
	# If not, initialize them.
	# This hash holds details of the set of options.

	$self -> param(key =>
	{
		option =>
		{
			columns_of_commands_option =>
			{
				default	=> 3,
				maximum	=> 20,
				minimum	=> 1,
				size	=> 2,
				type	=> 'integer',
			},
			records_per_page_option =>
			{
				default	=> 100,
				maximum	=> 1000,
				minimum	=> 1,
				size	=> 4,
				type	=> 'integer',
			},
		},
	});

	my(@key) = keys %{${$self -> param('key')}{'option'} };

	$self -> param($_ => $self -> session() -> param($_) ) for @key;

	# Pick any option to see if they've all be initialized.

	if (! $self -> param('records_per_page_option') )
	{
		my($value);

		for (@key)
		{
			$value = ${$self -> param('key')}{'option'}{$_}{'default'};

			$self -> param($_ => $value);
			$self -> session() -> param($_ => $value);
		}
	}

}	# End of cgiapp_init.

# --------------------------------------------------
# Note: This code retrieves the config in order to access 'dsn'.
# This illustrates a different method of accessing config data
# than, say, sub setup(). The latter uses the fact that some data
# (tmpl_path) has been copied out of the config into an app param.
# This copying took place near the start of sub cgiapp_init().
# In the same way (as the latter technique) sub start() uses
# css_url, which was also copied in sub cgiapp_init().

sub db_vendor
{
	my($self)	= @_;
	my($config)	= $self -> param('config');
	my($vendor)	= $$config{'dsn'} =~ /[^:]+:([^:]+):/;

	return $vendor;

}	# End of db_vendor.

# -----------------------------------------------
# Given a class we return an array of 3 elements:
# 0: An array ref of primary column names
# 1: An array ref of all other column names
# 2: An array ref of all column names
# The names are in the order returned by the class, which is best because
# the database designer probably set up the table with the columns in a
# specific order, and the names of the primary key columns are in a
# specific order anyway. And the caller can sort the [1] if desired.

sub get_columns
{
	my($self, $class)	= @_;
	my(@column)			= $class -> columns();
	my(@primary_column)	= $class -> primary_columns();

	my(%primary_column);

	@primary_column{@primary_column}	= (1) x @primary_column;
	my(@other_column)					= grep{! $primary_column{$_} } @column;

	return ([@primary_column], [@other_column], [@column]);

}	# End of get_columns.

# -----------------------------------------------

sub setup
{
	my($self) = @_;

	$self -> run_modes(start => \&start, update_options => \&update_options);
	$self -> tmpl_path($self -> param('tmpl_path') );

}	# End of setup.

# -----------------------------------------------

sub setup_db_interface
{
	my($self, $parameter )	= @_;
	my($classes)			= [];

	if (ref($parameter) eq 'ARRAY')
	{
		for my $cdbi_class (@$parameter)
		{
			# Check to see if it's loaded already.

			if (! $cdbi_class::)
			{
				my($file)	= $cdbi_class;
				$file		=~ s|::|/|g;

				eval
				{
					require "$file.pm";

					$cdbi_class -> import();
				};

				die "CGI::Application::Demo::setup_db_interface(): Couldn't require class: $cdbi_class: $@" if ($@);
			}

			push @$classes, $cdbi_class;
		}
	}
	elsif (ref($parameter) =~ /^Class::DBI::Loader/)
	{
		push @$classes, $_ for $parameter -> classes();
	}
	else
	{
		my($ref) = ref($parameter);

		die "CGI::Application::Demo::setup_db_interface(): Invalid parameter\nParameter must either be an array reference of Class::DBI classes or a Class::DBI::Loader object\nYou gave me a $ref object.";
	}

	$self -> param(cgi_app_demo_classes => $classes);

	my($tables) = {};

	for my $cdbi_class (@{$self -> param('cgi_app_demo_classes')})
	{
		my($table)			= $cdbi_class -> table();
		$$tables{$table}	= $cdbi_class;
	}

	$self -> param(cgi_app_demo_tables => $tables);

}	# End of setup_db_interface.

# -----------------------------------------------

sub start
{
	my($self)		= shift;
	my($config)		= $self -> param('config');
	my($submit)		= $self -> query() -> param('submit') || '';
	my($template)	= $self -> load_tmpl($$config{'tmpl_name'});
	my($content)	= $self -> build_basic_pane($submit) . $self -> build_options_pane($submit);

	$template -> param(content => $content);
	$template -> param(css_url => $self -> param('css_url') );
	$template -> param(rm => $self -> query() -> param('rm') );
	$template -> param(sid => $self -> session() -> id() );
	$template -> param(title => $self -> param('title') );
	$template -> param(url => $self -> query() -> url() . $self -> query() -> path_info() );

	return $template -> output();

}	# End of start.

# -----------------------------------------------

sub update_options
{
	my($self)	= @_;
	my(@key)	= keys %{${$self -> param('key')}{'option'} };

	$self -> log() -> info('Called update_options()');

	my($value, $default, $minimum, $maximum);

	for (@key)
	{
		$default	= ${$self -> param('key')}{'option'}{$_}{'default'};
		$minimum	= ${$self -> param('key')}{'option'}{$_}{'minimum'};
		$maximum	= ${$self -> param('key')}{'option'}{$_}{'maximum'};
		$value		= $self -> query() -> param($_);
		$value		= $default if (! defined($value) || ($value < $minimum) || ($value > $maximum) );

		$self -> param($_ => $value);
		$self -> session() -> param($_ => $value);
	}

	return $self -> start();

}	# End of update_options.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<CGI::Application::Demo> - A vehicle to showcase CGI::Application

=head1 Synopsis

	#!/usr/bin/perl

	use strict;
	use warnings;

	use CGI::Application::Demo;

	# -----------------------------------------------

	delete @ENV{'BASH_ENV', 'CDPATH', 'ENV', 'IFS', 'PATH', 'SHELL'}; # For security.

	CGI::Application::Demo -> new() -> run();

=head1 Description

C<CGI::Application::Demo> is a vehicle for the delivery of a sample C<CGI::Application> application, with these components:

=over 4

=item A set of CGI instance scripts

=item A set of text configuration files

=item A CSS file

=item A data file to help bootstrap populating the database

=item A set of command line scripts, to bootstrap populating the database

=item A set of HTML::Templates

=item A set of Perl modules

=over 4

=item CGI::Application::Demo

=item CGI::Application::Demo::One

=item CGI::Application::Demo::Two

=item CGI::Application::Demo::Three

=item CGI::Application::Demo::Four

=item CGI::Application::Demo::Five

=item CGI::Application::Demo::Base

=item CGI::Application::Demo::Create

=item CGI::Application::Demo::Faculty

=item CGI::Application::Demo::LogDispatchDBI

=back

=back

This module, C<CGI::Application::Demo>, demonstrates various features available to programs based on C<CGI::Application>:

=over 4

=item Probing a strange environment

=item Run modes and their subs

=item Disk-based session handling

=item Storing the session id in a hidden CGI form field

=item Using the session to store user-changeable options

=item Using C<Class::DBI> and C<Class::DBI::Loader> to auto-generate code per database table

=item Using C<HTML::Template> style templates

=item Changing the run mode with Javascript

=item Overriding the default query object

This replaces a C<CGI> object with a lighter-weight C<CGI::Simple> object.

=item Initialization via a configuration file

=item Switching database servers via the config file

=item Logging to a database table

=item Multiple inheritance, to support MySQL, Oracle and Postgres neatly

See C<CGI::Application::Demo::LogDispatchDBI>.

=back

Note: Because I use C<Class::DBI::Loader>, which wants a primary key in every table, and I use C<CGI::Session>,
I changed the definition of my 'sessions' table from this:

	create table sessions
	(
		id char(32) not null unique,
		a_session text not null
	);

to this:

	create table sessions
	(
		id char(32) not null primary key, # I.e.: 'unique' => 'primary key'.
		a_session text not null           # For Oracle, 'text' => 'long'.
	);

compared to what's recommended in the C<CGI::Session> docs.

Also, as you add complexity to this code, you may find it necessary to change line 10 of Base.pm from this:

	use base 'Class::DBI';

to something like this:

	use base $^O eq 'MSWin32' ? 'Class::DBI' : 'Class::DBI::Pg'; # Or 'Class::DBI::Oracle';

=head1 Probing a Strange Environment

The five modules One.pm .. Five.pm  have been designed so as to be graduated in complexity from simplistic to complex,
to help you probe the preculiarities of a strange environment.

Each module ships with a corresponding config file, instance script and template. Well, actually, One.pm and Two.pm are too simple
to warrant their own config files, and One.pm does not even need a template.

In each case, you are advised to examine the code in these modules while reading what follows.

Our plan then becomes:

=over 4

=item Run cgi-app-lib.cgi

This just tests your usage of 'use lib ...'.

By commenting this out, or not, you can check you're actually finding the system's C<CGI.pm>, or the one you installed.

Of course you can do this for any module, not just C<CGI.pm>.

When that's working, move on.

=item Use C<One.pm>

Run via cgi-app-one.cgi.

This adds usage of a module based on C<CGI::Application>, but the module itself has, deliberately, no complexity of its own.
It simple display a build-in web page.

When that's working, move on.

=item Use C<Two.pm>

Run via cgi-app-two.cgi.

This adds:

=over 4

=item Replacing C<CGI> with C<CGI::Simple>

See C<sub cgiapp_get_query()>.

=item Using C<HTML::Template>-style templates

See C<sub cgiapp_init()> and C<sub start()>.

=back

When that's working, move on.

=item Use C<Three.pm>

Run via cgi-app-three.cgi.

This adds:

=over 4

=item Using C<CGI::Application::Plugin::Config::Context>

Here for the first time we read a config file.

Naturally, you'll need to edit the config file to suit your environment.

=back

When that's working, move on.

=item Use C<Four.pm>

Run via cgi-app-four.cgi.

This adds:

=over 4

=item Using a CSS file

=item Getting a CSS's url from the config file

=item Getting a DSN, username, password and attributes from the config file

Now we're testing a more complex config file.

=item Use C<DBI>

And we use those parameters to test a direct connexion to the database.

We use this connexion to display all records in the C<faculty> table, using the CSS's url.

The C<faculty> table has no purpose other than to provide data to be displayed, either via C<DBI> or via C<Class::DBI>.

=back

When that's working, move on.

=item Use C<Five.pm>

Run via cgi-app-five.cgi.

WARNING

But first a warning. C<Base.pm> is used by both C<Five.pm> and C<Demo.pm>. You must edit line 77 of C<Base.pm>
to say either 'cgi-app-five.conf' or 'cgi-app-demo.conf', depending on which module you are testing.

Five.pm adds:

=over 4

=item Using a base module, C<Base.pm>, for all table modules

Actually, there's only per-table module, Faculty.pm, at this time, but at least you can see how to use a base module to share code
across table modules.

=item Using a dedicated module for the C<faculty> table: C<Faculty.pm>

=item Using C<Class::DBI::Loader>

This uses C<Class::DBI> to automatically load a module-per-table. C<DBIx::Class> provides similar features, but I've never used it.

As above, we just display all records in the C<faculty> table.

=back

By now, if successful, you will have tested all the components of C<Demo.pm>, one-by-one.

So, the next step is obvious...

=item Use C<Demo.pm>

Run via cgi-app-demo.cgi.

This adds

=over 4

=item Using C<CGI::Application::Plugin::LogDispatch>

Now we log things to a database table via C<LogDispatchDBI.pm> (below).

=item Using C<CGI::Application::Plugin::Session>

Now we use sessions stored in the database via C<CGI::Session>.

Install my module C<CGI::Session::Driver::oracle>, if necessary.

=item C<Create.pm>

The code to drop tables, create tables, and populate tables is all in this module.

This was a deliberate decision. For example, when everything's up and running, there is no need for your per-table modules such as
C<Faculty.pm> to contain code to do with populating tables, especially constant tables (as C<faculty> is in this demo).

=item C<Base.pm>

A module to share code between all per-table modules.

=item C<Faculty.pm>

A module dedicated to a specific table.

=item C<LogDispatchDBI.pm>

A module to customize logging via C<Log::Dispatch::DBI>.

=back

=back

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Order of Execution of subs within a C<CGI::Application>-based script:

=over 4

=item The instance script

The instance script (see Synopsis) contains 'use CGI::Application::Demo',
which causes Perl to load the file /perl/site/lib/CGI/Application/Demo.pm.

At this point the instance script is initialized, in that package C<CGI::Application::Demo>
has been loaded. The script has not yet started to run.

This package contains "use base 'CGI::Application'", meaning C<CGI::Application::Demo> is a
descendent of C<CGI::Application>. That is, C<CGI::Application::Demo> is-a C<CGI::Application>.

This (C<CGI::Application::Demo>) is what I'll call our application module.

What's confusing is that application modules can declare various hooks (a hook is an
alias for a sub) to be run before the sub corresponding to the current run mode.
Two of these hooked subs are called cgiapp_init() (hook is 'init'), and cgiapp_prerun() (hook is 'prerun').

Further, a sub prerun_mode() is also available.

None of these 3 sub are called yet, if at all.

=back

=head1 The instance script, revisited

Now CGI::Application::Demo -> new() is called, and it does what it has to do.

This is, it initializes a new object of type C<CGI::Application>.

This includes calling the 'init' hook (sub cgiapp_init() ) and sub setup(), if any.

Since we did in fact declare a sub cgiapp_init() (hook is 'init'), that gets called,
and since we also declared a sub setup(), that then gets called too.

You can see the call to setup() at the very end of C<CGI::Application>'s sub new().

Oh, BTW, during the call to cgiapp_init, there was a call to sub setup_db_interface(),
which, via the magic of C<Class::DBI::Loader>, tucks away an array ref of a list of classes, one
per database table, in the statement $self -> param(cgi_app_demo_classes => $classes), and an
array ref of a list of table names in the statement $self -> param(cgi_app_demo_tables => $tables).

=head1 The instance script, revisited, again

Now CGI::Application::Demo -> run() is called.

First, this calls our sub cgiapp_get_query() via a call to sub query(), which we declared
in order to use a light-weight object of type C<CGI::Simple>, rather than an object of type C<CGI>.

Then, eventually, our application module's run mode sub is called, which defaults to sub start().

So, sub start() is called, and it does whatever we told it to do. The app is up and running, finally.

=head1 Required Modules

=over 4

=item Carp

=item CGI::Application

=item CGI::Application::Plugin::Config::Context

=item CGI::Application::Plugin::LogDispatch

=item CGI::Application::Plugin::Session

=item CGI::Simple

=item Class::DBI

=item Class::DBI::Loader

=item Config::General

=item HTML::Template

=item Log::Dispatch::DBI

=back

=head1 Prerequisites of the Required Modules

This list has been moved into a separate document:

http://savage.net.au/Perl-modules/html/modules-for-a-new-pc.html

=head1 Installing the non-Perl components of this module

Unpack the distro, and you'll see various directories to be moved to where your web server
can find them.

=over 4

=item $distro/cgi-bin/cgi-app-demo/

These are CGI scripts.

=item $distro/conf/cgi-app-demo/

These are config files.

=item $distro/css/cgi-app-demo/

This is the one CSS file.

=item $distro/templates/cgi-app-demo/

These are the templates.

=back

Now you may have to edit a line or two in some files.

I realise all this seems to be a bit of an effort, but once you appreciate
the value of such configuation options, you'll adopt them as enthusiastically
as I have done. And you only do this once.

Here I just list the lines you should at least consider editing. Similar comments apply to all *.conf and *.pm files.

=over 4

=item cgi-app-demo.conf

	css_url=/css/cgi-app-demo/cgi-app-demo.css
	dsn=dbi:mysql:cgi_app_demo, username and password
	session_driver=driver:Oracle
	tmpl_path=/apache2/htdocs/templates/cgi-app-demo/

=item Demo.pm

	my($config_file) = ...;

=item Base.pm

	my($config_file) = ...;

=item cgi-bin/cgi-app-demo/cgi-app-demo.cgi

Patch the 'use lib' line if you've installed your modules in a non-standard location.

=item $distro/scripts/test-conf.pl

Patch, if necessary:

	my($config_file) = "$ENV{'ASSETS'}/conf/cgi-app-demo/cgi-app-demo.conf";

=item $distro/scripts/drop.pl, create.pl and populate.pl

In these, you need to set the environment variables (which are not used by *.cgi):

=over 4

=item ASSETS=/apache2

=item INSTALL=/perl/site/lib

=back

=back

=head1 Initializing the Database

Lastly, cd $distro/scripts/ and create and populate the database:

=over 4

=item perl drop.pl

=item perl create.pl

=item perl populate.pl

And finish off with...

=item test-conf.pl

=back

Now test http://127.0.0.1/cgi-bin/cgi-app-demo/cgi-app-lib.cgi, and each of cgi-app-(one,two,three,four,five).cgi in turn.

Finally, point your web client at http://127.0.0.1/cgi-bin/cgi-app-demo/cgi-app-demo.cgi and see what happens.

=head1 A Note about C<HTML::Entities>

In general, a CGI::Application-type app could be outputting any type of data whatsoever,
and will need to protect that data by encoding it appropriately. For instance, we want
to stop arbitrary data being interpreted as HTML.

The sub C<HTML::Entities::encode_entities()> is designed for precisely this purpose.
See that module's docs for details.

Now, in order to call that sub from within a double-quoted string, we need some sort
of interpolation facility. Hence the module C<HTML::Entities::Interpolate>.
See its docs for details.

This demo does not yet need or use C<HTML::Entities::Interpolate>.

=head1 Test Environments

I've tested these modules in these environments:

=over 4

=item GNU/Linux, Perl 5.8.0, Oracle 10gR1, Apache 1.3.33

=item GNU/Linux, Perl 5.8.0, Postgres 7.4.7, Apache 2.0.46

=item Win2K, Perl 5.8.6, MySQL 4.1.9, Apache 2.0.52

=back

=head1 Credits

I drew significant inspiration from code in the C<CGI::Application::Plugin::BREAD> project:

http://charlotte.pm.org/kwiki/index.cgi?BreadProject

I used those ideas to write my own bakermaker, the soon-to-be-released (Dec '05) C<DBIx::Admin>.

In fact, the current module is a cut-down version of C<DBIx::Admin>.

=head1 Author

C<CGI::Application::Demo> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2005.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2005, Ron Savage. All rights reserved.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
