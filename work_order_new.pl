#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);
use strict;
use warnings;
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

if($authenticated == 1){
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $sth;
	my $query;

	$query = "select * from wo;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $wo_list = $sth->fetchall_hashref('name');
	my @s_wo = sort({lc($a) cmp lc($b)} keys %$wo_list);

	$query = "select * from priority;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $priority_list = $sth->fetchall_hashref('id');

	$query = "select * from site where not deleted;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $site_list = $sth->fetchall_hashref('name');
	my @s_site = sort({lc($a) cmp lc($b)} keys %$site_list);

	my @styles = ("styles/work_order_new.css");
	my @javascripts = ("javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery.json-2.2.js","javascripts/jquery.mousewheel.js","javascripts/mwheelIntent.js","javascripts/jquery.jscrollpane.js","javascripts/jquery.tablesorter.js","javascripts/main.js","javascripts/work_order_new.js");
	my $title = $config->{'company_name'} . " - New Work Order";
	my $file = "work_order_new.tt";

	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, site_list => $site_list, priority_list => $priority_list, wo_list => $wo_list, ssite => \@s_site, swo => \@s_wo};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
