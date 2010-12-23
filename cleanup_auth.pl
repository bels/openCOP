#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use YAML;

my $config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
my $query = "select cleanup_auth()";
my $sth = $dbh->prepare($query);
$sth->execute;
