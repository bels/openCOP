#!/usr/bin/env perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;

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

if($authenticated == 1)
{
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $i;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select id,type from site_level";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $site_levels = $sth->fetchall_hashref('type');

	my @slid;
	foreach(keys %$site_levels){
		push(@slid,$_);
	}
	my @site_levels = sort({lc($a) cmp lc($b)} @slid);
	
	$query = "select id,name from site where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $sites = $sth->fetchall_hashref('name');

	my @sid;
	foreach(keys %$sites){
		push(@sid,$_);
	}
	my @sites = sort({lc($a) cmp lc($b)} @sid);
	
	$query = "select id,name from company";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $companies = $sth->fetchall_hashref('name');

	my @cid;
	foreach(keys %$companies){
		push(@cid,$_);
	}
	my @companies = sort({lc($a) cmp lc($b)} @cid);
	
	my $success = $q->param('success');
	my $level_success = $q->param('level_success');
	my $company_success = $q->param('company_success');
	my $associate_success = $q->param('associate_success');
	my $delete_site_success = $q->param('delete_site_success');
	my $delete_site_level_success = $q->param('delete_site_level_success');
	
	my @styles = ( "styles/sites.css");
	my @javascripts = ("javascripts/main.js","javascripts/sites.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $file = "sites.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title'				=>	$title,
		'styles'			=>	\@styles,
		'javascripts'			=>	\@javascripts,
		'keywords'			=>	$meta_keywords,
		'description'			=>	$meta_description,
		'company_name'			=>	$config->{'company_name'},
		logo				=>	$config->{'logo_image'},
		success				=>	$success,
		level_success			=>	$level_success,
		company_success			=>	$company_success,
		site_levels			=>	$site_levels,
		sites				=>	$sites,
		companies			=>	$companies,
		site_level_list			=>	\@site_levels,
		sites_list			=>	\@sites,
		company_list			=>	\@companies,
		associate_success		=>	$associate_success,
		delete_site_success		=>	$delete_site_success,
		delete_site_level_success	=>	$delete_site_level_success,
		is_admin			=>	$user->is_admin(id => $id),
	};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
