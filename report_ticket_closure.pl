#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $vars = $q->Vars;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query;
	my $sth;
	$query = "select id,alias from users where active;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $users = $sth->fetchall_hashref('id');
	
	if(defined($vars->{'init'})){
		my @styles = ("styles/layout.css","styles/reports.css");
		my @javascripts = (
			"javascripts/jquery.js",
			"javascripts/main.js",
			"javascripts/jquery.hoverIntent.minified.js",
			"javascripts/jquery.validate.js",
			"javascripts/jquery.blockui.js",
			"javascripts/jquery.livequery.js",
			"javascripts/reports.js"
		);
		my $title = $config->{'company_name'} . " - Ticket Closure Report";
		my $file = "report_ticket_closure.tt";
	
		my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, users => $users};
	
		print "Content-type: text/html\n\n";
	
		my $template = Template->new();
		$template->process($file,$vars) || die $template->error();
	} else {
		my $ticket_count = {};
		my $start_date = $vars->{'start_date'};
		my $end_date = $vars->{'end_date'};

		$query = "select report_ticket_closure(?,?,?);";
		$sth = $dbh->prepare($query);
	
		foreach (keys %$users){	
			$sth->execute($users->{$_}->{'alias'},$start_date,$end_date);
			$ticket_count->{$users->{$_}->{'alias'}} = $sth->fetchrow_hashref;
		}
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
