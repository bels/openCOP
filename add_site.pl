#!/usr/local/bin/perl

use strict;
use warnings;
use YAML ();
use CGI;
use DBI;

my $q = CGI->new();

my $config;
if (-e "config.yml")
{
	$config = YAML::LoadFile("config.yml");
}
else
{
	die "Config file (config.yml) does not exist or the permissions on it are not correct.\n";
}

my $sites = $config->{'sites'};
my @new_sites = @$sites; #sometype of evaluating needs to be done here.  If the sites array is empty in the config file this breaks.
push(@new_sites,$q->param('site_name'));

$config->{'sites'} = \@new_sites;

YAML::DumpFile("config.yml",$config);

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
my $site_level = $q->param('site_level');
my $query = "select * from school_level where type = '$site_level'";
my $sth = $dbh->prepare($query);
$sth->execute;
my $results = $sth->fetchrow_hashref;

my $site_name = $q->param('site_name');
$query = "insert into site (level,name) values ('$results->{'slid'}','$site_name')";
$sth = $dbh->prepare($query);
$sth->execute;

print $q->redirect(-URL=> "sites.pl");