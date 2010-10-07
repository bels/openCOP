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

my $section_name = uri_unescape($q->param('section_name'));
my $section_email = uri_unescape($q->param('section_email'));

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
my $query = "insert into section (name,email) values ('$section_name','$section_email')";
my $sth = $dbh->prepare($query);
$sth->execute;

print $q->redirect(-URL=> "global_settings.pl");