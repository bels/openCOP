#!/usr/local/bin/perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;

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
	my @site_levels = ();
	foreach my $site (@temp){
		push(@site_levels,shift(@$site));
	}
	
	$query = "select name from site where deleted != '1' or deleted is null";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$results = $sth->fetchall_arrayref;
	@temp = @$results; #required because fetchall_arrayref returns a reference to an array that has a reference to a 1 element array in each element
	my @sites = ();
	foreach my $site (@temp){
		push(@sites,shift(@$site));
	}
	
	$query = "select name from company";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$results = $sth->fetchall_arrayref;
	@temp = @$results; #required because fetchall_arrayref returns a reference to an array that has a reference to a 1 element array in each element
	my @companies = ();
	foreach my $company (@temp){
		push(@companies,shift(@$company));
	}
	
	my $success = $q->param('success');
	my $level_success = $q->param('level_success');
	my $company_success = $q->param('company_success');
	my $associate_success = $q->param('associate_success');
	my $delete_site_success = $q->param('delete_site_success');
	
	my @styles = ("styles/layout.css", "styles/sites.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $file = "sites.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, site_level_list => \@site_levels, success => $success,level_success => $level_success,company_success => $company_success, sites_list => \@sites, company_list => \@companies, associate_success => $associate_success,delete_site_success => $delete_site_success};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
