#!/usr/local/bin/perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use URI::Escape;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $site_level = uri_unescape($q->param('site_level_name'));

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
my $query = "insert into school_level (type) values ('$site_level')";
my $sth = $dbh->prepare($query);
$sth->execute;

print $q->redirect(-URL=> "sites.pl");