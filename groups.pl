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
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $i;
	my @pid;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $query = "select id,alias from users where active = true;";
	my $sth = $dbh->prepare($query);
	$sth->execute;

	my $uid = $sth->fetchall_hashref('alias');
	foreach(keys %$uid){
		push(@pid,$uid->{$_}->{'alias'});
	}
	my @uid = sort(@pid);

	$query = "select * from aclgroup;";
	$sth = $dbh->prepare($query);
	$sth->execute;

	my $gid = $sth->fetchall_hashref('name');
	@pid = [];
	foreach(keys %$gid){
		unless($gid->{$_}->{'name'} eq "customers"){
			push(@pid,$gid->{$_}->{'name'});
		}
	}
	shift(@pid);
	my @gid = sort(@pid);

	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/ui.multiselect.css","styles/groups.css");
	my @javascripts = ("javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/ui.multiselect.js","javascripts/main.js","javascripts/groups.js");

	my $file = "groups.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, users => \@uid, groups => \@gid, uid => $uid, gid => $gid, is_admin => $user->is_admin(id => $id)};
		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
