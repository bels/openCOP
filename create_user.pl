#!/usr/bin/env perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use UserFunctions;
use Data::Dumper;

my $q = CGI->new(); #create CGI
my $alias = uri_unescape($q->param('username')); #getting the username from the form
my $password = uri_unescape($q->param('password1')); #getting the password from the form
my $email = uri_unescape($q->param('email'));
my $section = uri_unescape($q->param('section'));

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
	my $config;
	if (-e "config.yml")
	{
		$config = YAML::LoadFile("config.yml");
	}
	else
	{
		die "Config file (config.yml) does not exist or the permissions on it are not correct.\n";
	}
	my $techs = $config->{'techs'};
	my @new_techs = @$techs; #sometype of evaluating needs to be done here.  If the sites array is empty in the config file this breaks.
	push(@new_techs,$alias);
	$config->{'techs'} = \@new_techs;

	YAML::DumpFile("config.yml",$config);
	$user->create_user(alias => $alias,password => $password, email => $email,section => $section);
	print $q->redirect(-URL => "user_admin.pl?success=1");
}