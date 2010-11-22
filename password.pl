#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;
use SessionFunctions;
use CustomerFunctions;
use UserFunctions;

#get the referrer so we know if we should display a internal page or a customer page.
my $q = CGI->new;
my $previous = $q->referer();
my $id = $q->param('id');
my $success = $q->param('success');
my $email_success = $q->param('email_success');
my $file;
my $customer;
my $type = uri_unescape($q->param('type'));
if(defined($type)){chomp $type};

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $id;
	if($previous =~ m/customer_/i || $type eq "customer")
	{
		$file = "customer_password.tt";
		$customer = 1;
		my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$id = $user->get_user_id(alias => $alias);
	} else {
		$file = "password.tt";
		$customer = 0;
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$id = $user->get_user_id(alias => $alias);
	}
	
	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/layout.css", "styles/password.css","styles/customer.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/jquery.validate.js","javascripts/password.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js");

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},customer => $customer,id => $id, success => $success, email_success => $email_success};
		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $previous);
}
