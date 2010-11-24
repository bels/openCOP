#!/usr/bin/env perl

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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

my $duplicate = $q->param('duplicate');
my $success = $q->param('success');

if($authenticated == 1)
{
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select id,alias from users where active = true;";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $uid = $sth->fetchall_hashref('id');
	
	my @styles = ("styles/layout.css","styles/user_admin.css","styles/ui.multiselect.css","styles/smoothness/jquery-ui-1.8.5.custom.css", "styles/groups.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/user_admin.js","javascripts/jquery.hoverIntent.minified.js","javascripts/groups.js","javascripts/jquery.livequery.js","javascripts/jquery.blockui.js","javascripts/jquery-ui-1.8.5.custom.min.js","javascripts/ui.multiselect.js","javascripts/main.js");
	my $meta_keywords = "";
	my $meta_description = "";
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select name from section";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchall_arrayref;
	my @temp = @$results; #required because fetchall_arrayref returns a reference to an array that has a reference to a 1 element array in each element
	my @sections = ();
	foreach my $section (@temp){
		push(@sections,shift(@$section));
	}
	my $file = "user_admin.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, duplicate => $duplicate, success => $success,logo => $config->{'logo_image'}, sections => \@sections,users => $uid};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
