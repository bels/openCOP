#!/usr/local/bin/perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my @styles = (
		"styles/ui.multiselect.css",
		"styles/reports.css"
	);
	my @javascripts = (
		"javascripts/jquery.validate.js",
		"javascripts/jquery.blockui.js",
		"javascripts/jquery.json-2.2.js",
		"javascripts/ui.multiselect.js",
		"javascripts/main.js",
		"javascripts/reports.js"
	);
	my $title = $config->{'company_name'} . " - Query Builder";
	my $file = "reports.tt";

	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		is_admin => $user->is_admin(id => $id),
		backend => $config->{'backend'},
	};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
