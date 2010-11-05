#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;

use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;

my @styles = ("styles/layout.css", "styles/index.css");
my @javascripts = ("javascripts/jquery.js","javascripts/index.js");
my $meta_keywords = "";
my $meta_description = "";

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
	print $q->redirect(-URL => "main.pl");
}
else
{
	my $vars;
	my $file = "index.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $errorcode = $q->param('errorcode');
	if($errorcode == 1){
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},'errorcode' => $errorcode};
	} else {
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}};
	}

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
