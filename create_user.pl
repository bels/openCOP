#!/usr/bin/env perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use UserFunctions;
use SessionFunctions;

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
	my $alias = uri_unescape($q->param('username')); #getting the username from the form
	my $password = uri_unescape($q->param('password1')); #getting the password from the form
	my $email = uri_unescape($q->param('email'));
	my $group = uri_unescape($q->param('group'));
	
	chomp($alias);
	chomp($password);
	
	my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");
	
	$config->read_config;
	
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	
	if($user->duplicate_check(alias => $alias) > 0)
	{
		my $errorpage = "user_admin.pl?duplicate=1";
		print $q->redirect(-URL=>$errorpage);
	}
	else
	{
		$user->create_user(alias => $alias,password => $password, email => $email,group => $group);
		print $q->redirect(-URL => "user_admin.pl?success=1");
	}
} elsif($authenticated == 2){
	print $q->redirect(-URL => $config->{'index_page'})
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}

