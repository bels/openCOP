#!/usr/local/bin/perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
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

my $duplicate = $q->param('duplicate');
my $success = $q->param('success');

if($authenticated == 1)
{
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my @styles = (
		"styles/customer.css"
	);
	my @javascripts = (
		"javascripts/jquery.validate.js",
		"javascripts/jquery.blockui.js",
		"javascripts/main.js",
		"javascripts/customer_admin.js",
	);
	my $meta_keywords = "";
	my $meta_description = "";
	my $file = "customer_admin.tt";

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select * from site where not deleted;";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $site_list = $sth->fetchall_hashref('id');

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'keywords' => $meta_keywords,
		'description' => $meta_description,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		site_list => $site_list,
		duplicate => $duplicate,
		success => $success,
		is_admin => $user->is_admin(id => $id),
		backend => $config->{'backend'}
	};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
