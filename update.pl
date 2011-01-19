#!/usr/bin/env perl

use strict;
use warnings;
use lib './libs';
use ReadConfig;
use Updater;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config;

my $updater = Updater->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $package;
my $backup_config;
my $backup_db;
my $merge;

my $version_check = $updater->check_version or die "Died checking version";

if($version_check->{'error'} == 1){
	$package = $updater->get_package(version => $version_check->{'calcv'}) or warn "Error getting package";

	if(defined($package->{'error'}) && $package->{'error'}){
		warn $package->{'message'};
	} else {
		$backup_config = $updater->backup_config;
		$backup_db = $updater->backup_db(db_user => $config->{'db_user'}, db_name => $config->{'db_name'});
	}
	
	if(defined($backup_config) && $backup_config){
		warn "Backing up configuration may have encountered errors. Verify manually\n";
	}
	if(defined($backup_db) && $backup_db){
		die "Encountered errorrs while backing up database. Verify that the database is running and try again.\n";
	} else {
		$merge = $updater->merge_changes(package_path => $package->{'package_path'});
		$updater->update_db(version => $version_check->{'calcc'}, newversion => $version_check->{'calcv'}, package_path => $package->{'package_path'});
		my $update_config = $updater->update_config(version => $version_check->{'version'});
	}

	if(defined($merge) && $merge){
		warn "Error encountered extracting updated files from tar. Check permissions.";
	} else {
		$updater->destroy;
	}
} else {
	warn $version_check->{'message'};
	print "Content-type: text/html\n\n";
}


print "Content-type: text/html\n\n";
