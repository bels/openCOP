#!/usr/local/bin/perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use SessionFunctions;
use CustomerFunctions;
use Digest::MD5 qw(md5_hex);

my $q = CGI->new(); #create CGI
my $alias = uri_unescape($q->param('username')); #getting the username from the form
my $password = uri_unescape($q->param('password')); #getting the password from the form

chomp($alias);
chomp($password);

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

my $success = $session->authenticate_user(users_table => "customers", alias => $alias, password => $password);

if($success)
{
	my $session_key = md5_hex(localtime);

	my $session_id = $session->create_session_id(auth_table => $config->{'auth_table'}, session_key => $session_key, uid => $alias) or die "Creating the session in the database failed";
	my $cookie = $q->cookie(-name=>'session',-value=>{'sid' => $session_id,'session_key' => $session_key},-expires=>'+1h') or die "Creating the cookie failed";

	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $user->get_user_id(alias => $alias);
	print $q->redirect(-cookie=>$cookie,-URL=>"customer.pl?id=$id");
}
else
{
	my $errorpage = "error.pl?errorcode=1";
	print $q->redirect(-URL=>$errorpage);
}