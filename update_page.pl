#!/usr/bin/env perl

use strict;
use warnings;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use Updater;

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

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $update = Updater->new;

	my $version = $update->check_version;
	my $cversion = $config->{'version'};

	warn $version;
	warn $cversion;

	my @styles = ( "styles/update_page.css");
	my @javascripts = ("javascripts/update_page.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $file = "update_page.tt";
	my $title = $config->{'company_name'} . " - Update";
	my $errorcode = $q->param('errorcode');
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'keywords' => $meta_keywords,
		'description' => $meta_description,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		is_admin => $user->is_admin(id => $id),
		backend => $config->{'backend'},
		version => $version->{'version'},
		cversion => $cversion,
	};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => "index.pl");
}
