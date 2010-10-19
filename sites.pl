#!/usr/local/bin/perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;

my @styles = ("styles/layout.css");
my @javascripts = ("javascripts/jquery.js","javascripts/main.js");
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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
	my $query = "select type from school_level";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchall_arrayref;
	my @temp = @$results; #required because fetchall_arrayref returns a reference to an array that has a reference to a 1 element array in each element
	my @sites = ();
	foreach my $site (@temp){
		push(@sites,shift(@$site));
	}
	my $success = $q->param('success');
	my $level_success = $q->param('level_success');
	my $company_success = $q->param('company_success');
	my $file = "sites.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, site_level_list => \@sites, success => $success,level_success => $level_success,company_success => $company_success};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}