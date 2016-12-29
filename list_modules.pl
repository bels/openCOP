#!/usr/local/bin/perl

use lib './libs';
use strict;
use warnings;
use DBI;
use ReadConfig;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config;

#### Building list of available modules
my @modules;
opendir DIRH, "./modules" or die "Couldn't open $!";
foreach (sort readdir DIRH){
	open FILE, "./modules/$_" or warn "Couldn't open $!";
	foreach (<FILE>){
		if($_ =~ m/MODULE_NAME/){
			my @scratch = split(/=/,$_);
			push(@modules,$scratch[1]);
		}
	}
}
#######################

####checking if the module is enabled in the database
my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
my $query = "select * from enabled_modules";
my $sth = $dbh->prepare($query);
$sth->execute;
my $result = $sth->fetchall_hashref('id');
########################

print "Content-type: text/html\n\n";
print qq(<label class="module_label"></label><span class="styled_text">Enabled</span><br />);
#### creating list of enabled and disabled modules
my $enabled;
foreach my $module (@modules){
	$enabled = 0;
	foreach my $key (%$result){
		chomp($module);
		if(defined($result->{$key}->{'module_name'})){
			if($module eq $result->{$key}->{'module_name'}){
				print qq(<label for="$key" class="module_label">$result->{$key}->{'module_name'}</label><input type=checkbox name="$key" id="$key" class="module" checked><br/>);
				$enabled = 1;
			}
		}
	}
	if($enabled == 0){
		print qq(<label for="$module" class="module_label">$module</label><input type=checkbox name="$module" id="module" class="module"><br/>);
	}
}
##########################
