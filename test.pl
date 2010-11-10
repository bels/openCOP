#!/usr/bin/env perl
use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;
use SessionFunctions;
use UserFunctions;
use YAML;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

#sub isequal($$){
#	if(defined($_[0]) && $_[0] == 0){
#		return $_[0];
#	} else {
#		return $_[1];
#	}
#}

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
#	my $sth;
	my $alias = "admin";
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $user->get_user_id(alias => $alias);
#	my $permissions = {};
#
#	my $query = "select distinct(aclgroup_id) from alias_aclgroup where (alias_id = '$id');";
#	$sth = $dbh->prepare($query);
#	$sth->execute;
#	my $group = $sth->fetchall_hashref('aclgroup_id');
#	foreach (keys %$group){
#		$query = "select * from section_aclgroup where aclgroup_id = '$_';";
#		$sth = $dbh->prepare($query);
#		$sth->execute;
#		my $finalgroup1 = $sth->fetchall_hashref('id');
#		foreach (keys %$finalgroup1){
#			$permissions->{$finalgroup1->{$_}->{'section_id'}} = {
#				'read'		=>	isequal($permissions->{$finalgroup1->{$_}->{'section_id'}}->{'read'},$finalgroup1->{$_}->{'aclread'}),
#				'create'	=>	isequal($permissions->{$finalgroup1->{$_}->{'section_id'}}->{'create'},$finalgroup1->{$_}->{'aclcreate'}),
#				'update'	=>	isequal($permissions->{$finalgroup1->{$_}->{'section_id'}}->{'update'},$finalgroup1->{$_}->{'aclupdate'}),
#				'delete'	=>	isequal($permissions->{$finalgroup1->{$_}->{'section_id'}}->{'delete'},$finalgroup1->{$_}->{'acldelete'}),
#			};
#		}
#	}

	my $permissions = $user->get_permissions(id => $id);
	my $group = $user->get_groups(id => $id);
YAML::DumpFile("temp.yaml",$permissions);
YAML::DumpFile("tempgroup.yaml",$group);
