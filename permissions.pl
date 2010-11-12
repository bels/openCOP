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


my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");
my $q = CGI->new();

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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;

	$query = "select * from aclgroup;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $gid = $sth->fetchall_hashref('id');

	$query = "select * from section;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $sid = $sth->fetchall_hashref('id');

	$query = "select * from section_aclgroup;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $gsp = $sth->fetchall_hashref('id');

#	$query = "select section.name,aclgroup.name,section_aclgroup.id,section_aclgroup.aclgroup_id,section_aclgroup.section_id,section_aclgroup.aclread,section_aclgroup.aclcreate,section_aclgroup.aclupdate,section_aclgroup.aclcomplete from section_aclgroup join section on section.id = section_aclgroup.section_id join aclgroup on aclgroup.id = section_aclgroup.aclgroup_id;";

	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/layout.css", "styles/permissions.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/jquery.validate.js","javascripts/permissions.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.livequery.js","javascripts/jquery.blockui.js");

	my $file = "permissions.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, groups => $gid, sections => $sid, gsp => $gsp};
		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
