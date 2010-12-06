#!/usr/bin/env perl

use lib './libs';
use strict;
use warnings;
use DBI;
use ReadConfig;
use CGI;

my $q = CGI->new();
my $module = $q->param('name');
my $action = $q->param('action');

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");
$config->read_config;

if($action eq 'enable'){
	my $module_name;
	my $filename;

	opendir DIRH, "./modules" or die "Couldn't open $!";
	foreach (sort readdir DIRH){
		open FILE, "./modules/$_" or warn "Couldn't open $!";
		my $file = $_;
		foreach (<FILE>){
			if($_ =~ m/MODULE_NAME/){
				my @scratch = split(/=/,$_);
				chomp($module);
				chomp($scratch[1]);
				if($module eq $scratch[1]){
					$module_name = $scratch[1];
					$filename = $file;
				}
			}
		}
	}

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "insert into enabled_modules (module_name,filename) values(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($module_name,$filename);

	qx(./modules/$filename enable);
}

if($action eq 'disable')
{
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select * from enabled_modules where id = $module";
	my $sth = $dbh->prepare($query);
	$sth->execute();
	my $results = $sth->fetchrow_hashref;
	my $filename = $results->{'filename'};
	$query = "delete from enabled_modules where id = $module";
	$sth = $dbh->prepare($query);
	$sth->execute();
	
	qx(./modules/$filename disable);
}
