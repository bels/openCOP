#!/usr/bin/env perl

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

my $company_name = uri_unescape($q->param('company_name_input'));

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
my $query = "insert into company (name,hidden) values ('$company_name',false)";
my $sth = $dbh->prepare($query);
$sth->execute;

print $q->redirect(-URL=> "sites.pl?company_success=1");