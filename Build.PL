use Module::Build;

Module::Build -> new
(
	module_name		=> 'CGI::Application::Demo',
	license			=> 'artistic',
	dist_author		=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires		=>
	{
		Carp										=> 0,
		CGI::Application							=> 0,
		CGI::Application::Plugin::Config::Context	=> 0,
		CGI::Application::Plugin::LogDispatch		=> 0,
		CGI::Application::Plugin::Session			=> 0,
		CGI::Session								=> 0,
		CGI::Simple									=> 0,
		Class::DBI									=> 0,
		Class::DBI::Loader							=> 0,
		Config::Context								=> 0,
		Config::General								=> 0,
		FindBin::Real								=> 0,
		HTML::Template								=> 0,
		Log::Dispatch::DBI							=> 0,
	},
) -> create_build_script();