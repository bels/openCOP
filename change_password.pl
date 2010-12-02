#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Digest::MD5 qw(md5_hex);
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

if($authenticated){
	my $old_password1 = uri_unescape($q->param('old_password'));
	my $password1 = uri_unescape($q->param('password1'));
	my $password2 = uri_unescape($q->param('password2'));
	
	my $old_password = md5_hex($old_password1);
	my $password = md5_hex($password1);
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	
	my $query = "select password from users where id = ?;";
	my $sth = $dbh->prepare($query);
	$sth->execute($id);
	my $old_password_ref = $sth->fetchrow_hashref;
	
	if($old_password eq $old_password_ref->{'password'}){
		my $query = "update users set password = ? where id = ?";
		my $sth = $dbh->prepare($query);
		$sth->execute($password,$id);
		print $q->redirect(-URL=> "password.pl?success=1");
	} else {
		print $q->redirect(-URL=> "password.pl?success=0");
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
