#!/usr/bin/env perl

use strict;
use warnings;
use YAML ();
use CGI;
use DBI;

my $config;
if (-e "config.yml")
{
	$config = YAML::LoadFile("config.yml");
}
else
{
	die "Config file (config.yml) does not exist or the permissions on it are not correct.\n";
}

my $q = CGI->new();

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
my $site_level = $q->param('site_level');
my $query = "select * from site_level where type = '$site_level'";
my $sth = $dbh->prepare($query);
$sth->execute;
my $results = $sth->fetchrow_hashref;

# Get the list of available sites
$query = "select * from site where not deleted;";
$sth = $dbh->prepare($query);
$sth->execute;
my $site_list = $sth->fetchall_hashref('id');

my $site_name = $q->param('site_name');
$query = "insert into site (level,name) values ('$results->{'id'}','$site_name')";
$sth = $dbh->prepare($query);
$sth->execute;

print $q->redirect(-URL=> "sites.pl?success=1");
