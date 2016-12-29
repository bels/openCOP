#!/usr/local/bin/perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use POSIX 'strftime';

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $query = "select id,alias from users where active = true and id not in (select alias_id from alias_aclgroup where aclgroup_id = (select id from aclgroup where name = 'customers'));";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my @pid;

	my $uid = $sth->fetchall_hashref('alias');
	foreach(keys %$uid){
		push(@pid,$uid->{$_}->{'alias'});
	}
	my @uid = sort(@pid);
	my $date = strftime( '%m/%d/%Y', localtime);

	my @styles = (
		"styles/ui.jqgrid.css",
		"styles/main.css",
		"styles/time_tracking.css",
		"styles/ticket_details.css",
	);
	my @javascripts = (
		"javascripts/grid.locale-en.js",
		"javascripts/jquery.tools.min.js",
		"javascripts/jquery.form.js",
		"javascripts/jquery.jqGrid.min.js",
		"javascripts/main.js",
		"javascripts/time_tracking.js",
	);
	my $meta_keywords = "";
	my $meta_description = "";
	my $file = "time_tracking.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'keywords' => $meta_keywords,
		'description' => $meta_description,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		is_admin => $user->is_admin(id => $id),
		backend => $config->{'backend'},
		uid => \@uid,
		users => $uid,
		date => $date,
	};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
