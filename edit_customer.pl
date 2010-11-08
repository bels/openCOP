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

my $id = $q->param('id');
my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
my $var = "customers";
my $id_field = "cid";


my $mode = $q->param('type');
if($mode eq "password"){
	my $password1 = uri_unescape($q->param('password1'));
	my $password = md5_hex($password1);
	my $query = "update $var set password = '$password' where $id_field = $id";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	print $q->redirect(-URL=> "customer_edit.pl?password_success=1&id=$id");
} elsif ($mode eq "email"){
	my $email1 = uri_unescape($q->param('email1'));
	my $email = $email1;
	my $query = "update $var set email = '$email' where $id_field = $id";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	print $q->redirect(-URL=> "customer_edit.pl?email_success=1&id=$id");
}
