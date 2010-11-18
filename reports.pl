#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my @styles = ("styles/layout.css","styles/reports.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery.livequery.js","javascripts/jquery.json-2.2.js","javascripts/main.js","javascripts/reports.js");
	my $title = $config->{'company_name'} . " - Query Builder";
	my $file = "reports.tt";

	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
