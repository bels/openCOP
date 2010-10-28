#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use CustomerFunctions;

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
	my @styles = ("styles/layout.css", "styles/customer.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/ticket.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my @site_list = $config->{'sites'};
	my @priority_list = $config->{'priority'};
	my @section_list = $config->{'sections'};

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},sid => $cookie{'sid'});

	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $cid = $user->get_user_info(alias => $alias);
	my $submitter = $cid->{'first'} . " " . $cid->{'last'};

	my $file = "customer.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},site_list => @site_list, priority_list => @priority_list, section_list => @section_list, author => $submitter};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	my $errorcode = $q->param('errorcode');
	my $vars;
	my @styles = ("styles/layout.css", "styles/customer.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/ticket.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	
	if ($errorcode == 1){
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},'errorcode' => $errorcode};		
	} else {
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}};
	}

	my $file = "customer_login.tt";
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
