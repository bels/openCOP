#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
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

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $user->get_user_id(alias => $alias);
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "
		select
			name,
			section_aclgroup.section_id
		from
			section_aclgroup
			join section on section.id = section_aclgroup.section_id
		where
			aclgroup_id in (
				select
					distinct(aclgroup_id)
				from
					alias_aclgroup
				where (
					alias_id = ?
				)
			)
		and
			section_aclgroup.aclread;
	";
	my $sth = $dbh->prepare($query);
	$sth->execute($id);
	my $section_list = $sth->fetchall_hashref('section_id');

	$query = "
		select
			name,
			section_aclgroup.section_id
		from
			section_aclgroup
			join
				section on section.id = section_aclgroup.section_id
		where
			aclgroup_id in (
				select
					distinct(aclgroup_id)
				from
					alias_aclgroup
				where (
					alias_id = ?
				)
			)
		and
			section_aclgroup.aclcreate;
	";
	$sth = $dbh->prepare($query);
	$sth->execute($id);
	my $section_create_list = $sth->fetchall_hashref('section_id');

	$section_list->{'pseudo'} = {
		'section_id'	=>	"pseudo",
		'name'		=>	"Tickets assigned directly",
	};

	$query = "select * from priority;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $priority_list = $sth->fetchall_hashref('id');

	$query = "select * from site where not deleted;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $site_list = $sth->fetchall_hashref('id');

	$query = "select id,alias from users where active;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $tech_list = $sth->fetchall_hashref('id');

	my @styles = ("styles/layout.css","styles/smoothness/jquery-ui-1.8.5.custom.css","styles/work_orders.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/jquery-ui-1.8.5.custom.min.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery.livequery.js","javascripts/jquery.json-2.2.js","javascripts/jquery.mousewheel.js","javascripts/mwheelIntent.js","javascripts/jquery.jscrollpane.js","javascripts/jquery.tablesorter.js","javascripts/main.js","javascripts/work_orders.js");
	my $title = $config->{'company_name'} . " - Work Orders";
	my $file = "work_order_new.tt";

	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, site_list => $site_list, priority_list => $priority_list, section_list => $section_list, tech_list => $tech_list, section_create_list => $section_create_list};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
