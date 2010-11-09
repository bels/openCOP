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
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $old_password1 = uri_unescape($q->param('old_password'));
my $password1 = uri_unescape($q->param('password1'));
my $password2 = uri_unescape($q->param('password2'));

my $old_password = md5_hex($old_password1);
my $password = md5_hex($password1);
my $id = $q->param('id');
my $id_field;
my $var;
my $type;

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
if(defined($q->param('customer'))){
	if($q->param('customer') == 1)
	{
		$var = "customers";
		$id_field = "id";
		$type = "customer"
	}
} else	{
	$var = "users";
	$id_field = "id";
	$type = "user";
}

my $query = "select password from $var where $id_field = $id;";
my $sth = $dbh->prepare($query);
$sth->execute;
my $old_password_ref = $sth->fetchrow_hashref;

if($old_password eq $old_password_ref->{'password'}){
	my $query = "update $var set password = '$password' where $id_field = $id";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	print $q->redirect(-URL=> "password.pl?success=1&id=$id&type=$type");
} else {
	print $q->redirect(-URL=> "password.pl?success=0&id=$id&type=$type");
}
