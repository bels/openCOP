#!/usr/bin/env perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;

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

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $i;
	my @pid;

	my $query = "select id,alias from users where active = true;";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $uid_list = $sth->fetchall_hashref('alias');
	foreach(keys %$uid_list){
		push(@pid,$uid_list->{$_}->{'alias'});
	}
	my @uid = sort(@pid);
	
	my @styles = (
		"styles/user_admin.css",
		"styles/ui.multiselect.css",
		"styles/groups.css"
	);
	my @javascripts = (
		"javascripts/groups.js",
		"javascripts/jquery.blockui.js",
		"javascripts/ui.multiselect.js",
		"javascripts/main.js"
	);
	my $meta_keywords = "";
	my $meta_description = "";

	my $query = "select * from aclgroup";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $gid_list = $sth->fetchall_hashref('name');
	@pid = [];
	foreach(keys %$gid_list){
		unless($gid_list->{$_}->{'name'} eq "customers"){
			push(@pid,$gid_list->{$_}->{'name'});
		}
	}
	my @gid = sort(@pid);
	shift(@gid);

	my $file = "user_admin.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'keywords' => $meta_keywords,
		'description' => $meta_description,
		'company_name' => $config->{'company_name'},
		duplicate => $duplicate,
		success => $success,
		logo => $config->{'logo_image'},
		groups => \@gid,
		users => \@uid,
		uid => $uid_list,
		gid => $gid_list,
		is_admin => $user->is_admin(id => $id),
		backend => $config->{'backend'},
	};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
