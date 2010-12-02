#!/usr/bin/env perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use DBI;
use SessionFunctions;
use UserFunctions;
use Notification;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

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
	my $q = CGI->new(); #create CGI
	my $alias = uri_unescape($q->param('username')); #getting the username from the form
	my $password = uri_unescape($q->param('password1')); #getting the password from the form
	my $email = uri_unescape($q->param('email'));
	my $first = uri_unescape($q->param('first'));
	my $mi = uri_unescape($q->param('middle_initial'));
	my $last = uri_unescape($q->param('last'));
	my $site = uri_unescape($q->param('site'));
	
	chomp($alias);
	chomp($password);
	
	my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");
	
	$config->read_config;
	
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	
	if($user->duplicate_check(alias => $alias) > 0)
	{
		my $errorpage = "customer_admin.pl?duplicate=1";
		print $q->redirect(-URL=>$errorpage);
	}
	else
	{
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $query = "select id from aclgroup where name = 'customers';";
		my $sth = $dbh->prepare($query);
		$sth->execute;
		my $result = $sth->fetchrow_hashref;
		my $group = $result->{'id'};

		$user->create_user(alias => $alias,password => $password, email => $email, first => $first, mi => $mi, last =>$last, site => $site, group => $group);
		my $notify = Notification->new(ticket_number => '1');
		$notify->new_user(mode => 'new_user', to => $email, first => $first, mi => $mi, last =>$last, password => $password, alias => $alias);
		print $q->redirect(-URL => "customer_admin.pl?success=1");	
	}
} elsif($authenticated == 2){
	print $q->redirect(-URL => $config->{'index_page'})
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
