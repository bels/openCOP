#!/usr/local/bin/perl

use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;
use SessionFunctions;
use UserFunctions;
use ReportFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
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
	my $report = ReportFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $reports = $report->view(id => $id);

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;
	my $i;
	my @pid;

	$query = "select * from aclgroup where name != 'admins';";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $gid_list = $sth->fetchall_hashref('name');
	$sth->execute;
	my $gid = $sth->fetchall_hashref('id');

	foreach(keys %$gid_list){
		push(@pid,$gid_list->{$_}->{'name'});
	}
	my @gid = sort({lc($a) cmp lc($b)}@pid);

	$query = "select * from section where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $sid_list = $sth->fetchall_hashref('name');
	$sth->execute;
	my $sid = $sth->fetchall_hashref('id');

	@pid = [];
	foreach(keys %$sid_list){
		push(@pid,$sid_list->{$_}->{'name'});
	}
	shift(@pid);
	my @sid = sort({lc($a) cmp lc($b)} @pid);

	$query = "select * from section_aclgroup where aclgroup_id != (select id from aclgroup where aclgroup.name = 'admins');";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $gsp = $sth->fetchall_hashref('id');

#	$query = "select section.name,aclgroup.name,section_aclgroup.id,section_aclgroup.aclgroup_id,section_aclgroup.section_id,section_aclgroup.aclread,section_aclgroup.aclcreate,section_aclgroup.aclupdate,section_aclgroup.aclcomplete from section_aclgroup join section on section.id = section_aclgroup.section_id join aclgroup on aclgroup.id = section_aclgroup.aclgroup_id;";

	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/permissions.css");
	my @javascripts = ("javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/main.js","javascripts/permissions.js");

	my $file = "permissions.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, groups => $gid, sections => $sid, gsp => $gsp, gid_list => \@gid, sid_list => \@sid, groups_names => $gid_list, sections_names => $sid_list, is_admin => $user->is_admin(id => $id), reports => $reports};
		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
