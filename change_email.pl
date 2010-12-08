#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Digest::MD5 qw(md5_hex);

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	my $email1 = uri_unescape($q->param('email1'));
	
	my $password1 = uri_unescape($q->param('password'));
	
	my $password = md5_hex($password1);
	my $email = $email1;
	my $id = $q->param('id');
	my $id_field;
	my $var;
	my $type;
	
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	if($q->param('customer') == 1)
	{
		$var = "customers";
		$id_field = "id";
		$type = "customer"
	}
	else
	{
		$var = "users";
		$id_field = "id";
		$type = "user";
	}
	
	my $query = "select password from $var where $id_field = $id;";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $password_ref = $sth->fetchrow_hashref;
	
	if($password eq $password_ref->{'password'}){
		my $query = "update $var set email = '$email' where $id_field = $id";
		my $sth = $dbh->prepare($query);
		$sth->execute;
		print $q->redirect(-URL=> "password.pl?email_success=1&id=$id&type=$type");
	} else {
		print $q->redirect(-URL=> "password.pl?email_success=0&id=$id&type=$type");
	}
} elsif($authenticated == 2){
	print $q->redirect(-URL => $config->{'index_page'})
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
