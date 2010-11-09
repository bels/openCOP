#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;
use SessionFunctions;
use UserFunctions;
use DBI;


#get the referrer so we know if we should display a internal page or a customer page.
my $q = CGI->new;
my $previous = $q->referer();
my $id = $q->param('id');
my $file;

my $params = $q->Vars;

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
	$file = "customer_edit.tt";
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	$id = $user->get_user_id(alias => $alias);
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query = "select * from customers;";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $customers = $sth->fetchall_hashref('id');

	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/layout.css", "styles/customer_edit.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/jquery.validate.js","javascripts/customer_edit.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js");

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, customers => $customers, password_success => $params->{'password_success'}, email_success => $params->{'email_success'}};
		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $previous);
}
