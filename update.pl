#!/usr/bin/env perl

use strict;
use warnings;
use lib './libs';
use ReadConfig;
use Updater;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config;

my $updater = Updater->new;
my $package;
my $backup;
my $merge;

my $version_check = $updater->check_version or die "Died checking version";

if($version_check->{'error'}){
	$package = $updater->get_package(version => $version_check->{'version'}) or warn "Error getting package";

	if(defined($package->{'error'}) && $package->{'error'}){
		warn $package->{'message'};
	} else {
		$backup = $updater->backup_config;
	}
	
	if(defined($backup) && $backup){
		warn "Backing up configuration may have failed. Verify manually\n";
	} else {
		$merge = $updater->merge_changes(package_path => $package->{'package_path'});
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
