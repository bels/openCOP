#!/usr/local/bin/perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use UserFunctions;
use Digest::MD5 qw(md5_hex);

my $q = CGI->new(); #create CGI
my $alias = uri_unescape($q->param('username')); #getting the username from the form
my $password = uri_unescape($q->param('password1')); #getting the password from the form
my $email = uri_unescape($q->param('email'));

chomp($alias);
chomp($password);

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

if($user->duplicate_check() > 0)
{
	my $errorpage = "user_admin.pl?duplicate=1";
	print $q->redirect(-URL=>$errorpage);
}
else
{
	$user->create_user(alias => $alias,password => $password, email => $email);
	print $q->redirect(-URL => "user_admin.pl?success=1");
}