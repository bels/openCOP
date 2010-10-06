#!/usr/local/bin/perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use ReadConfig;
use DBI;
use CustomerFunctions;

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

my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

if($user->duplicate_check(alias => $alias) > 0)
{
	my $errorpage = "customer_admin.pl?duplicate=1";
	print $q->redirect(-URL=>$errorpage);
}
else
{
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
	my $site_level = $q->param('site_level');
	my $query = "select * from site where name = '$site'";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchrow_hashref;
	$user->create_user(alias => $alias,password => $password, email => $email, first => $first, mi => $mi, last =>$last, site =>$results->{'scid'});
	print $q->redirect(-URL => "customer_admin.pl?success=1");
}