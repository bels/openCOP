#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $query;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $data;
	my $in_groups;
	my @in_groups_order;
	my $in_users;
	my @in_users_order;

	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "init_ug"){
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		my $id = $vars->{'uid'};
		$in_groups = $user->get_groups(id => $id);
		@in_groups_order = sort (keys %$in_groups);
	
		$query = "select * from aclgroup;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_groups  = $sth->fetchall_hashref('id');
		my @all_groups_order = sort (keys %$all_groups);
		my @in_groups;
	
		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="ug_select_array[]">
		);
	
		if(defined($in_groups)){
			foreach my $key (@in_groups_order){
				push(@in_groups,$in_groups->{$key}->{'aclgroup_id'});
				$data .= qq(<option selected="selected" value="$in_groups->{$key}->{'aclgroup_id'}">$in_groups->{$key}->{'name'}</option>);
			}
		}

		foreach my $key (@all_groups_order){
			foreach (@in_groups){
				if($_ =~ m/$all_groups->{$key}->{'id'}/) {
					delete($all_groups->{$key});
				}
			}
			if(defined($all_groups->{$key})){
				$data .= qq(<option value="$all_groups->{$key}->{'id'}">$all_groups->{$key}->{'name'}</option>);
			}
		}
	
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "init_gu"){
		my $id = $vars->{'gid'};
		my $query = "select distinct(alias_aclgroup.alias_id),alias from alias_aclgroup join users on alias_aclgroup.alias_id = users.id where (aclgroup_id = '$id');";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$in_users = $sth->fetchall_hashref('alias_id');
		@in_users_order = sort (keys %$in_users);

		$query = "select id,alias from users where active = true;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_users  = $sth->fetchall_hashref('id');
		my @all_users_order = sort (keys %$all_users);

		my @in_users;
	
		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="gu_select_array[]">
		);
	
		if(defined($in_users)){
			foreach my $key (@in_users_order){
				push(@in_users,$in_users->{$key}->{'alias_id'});
				$data .= qq(<option selected="selected" value="$in_users->{$key}->{'alias_id'}">$in_users->{$key}->{'alias'}</option>);
			}
		}

		foreach my $key (@all_users_order){
			foreach (@in_users){
				if($_ =~ m/$all_users->{$key}->{'id'}/) {
					delete($all_users->{$key});
				}
			}
			if(defined($all_users->{$key})){
				$data .= qq(<option value="$all_users->{$key}->{'id'}">$all_users->{$key}->{'alias'}</option>);
			}
		}
	
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "associate_ug"){
		my $uid = $vars->{'uid'};
		my $selected_string = $vars->{'selected'};
		my $unselected_string = $vars->{'unselected'};
		my $error;

		for($selected_string,$unselected_string){
			$_ =~ s/:$//;
		}

		my @selected = split(":",$selected_string);
		my @unselected = split(":",$unselected_string);

		for (@unselected) {
			$query = "delete from alias_aclgroup where alias_id = '$uid' and aclgroup_id = '$_';";
			$sth = $dbh->prepare($query);
			$sth->execute;
		}

		for (@selected) {
			$query = "select count(*) from alias_aclgroup where alias_id = '$uid' and aclgroup_id = '$_';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $count = $sth->fetchrow_hashref;
			unless($count->{'count'}){
				$query = "insert into alias_aclgroup(alias_id,aclgroup_id) values('$uid','$_');";
				$sth = $dbh->prepare($query);
				$sth->execute;
			} else {
				$error++;
			}
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
		}
	} elsif ($vars->{'mode'} eq "associate_gu"){
		my $gid = $vars->{'gid'};
		my $selected_string = $vars->{'selected'};
		my $unselected_string = $vars->{'unselected'};
		my $error;

		for($selected_string,$unselected_string){
			$_ =~ s/:$//;
		}

		my @selected = split(":",$selected_string);
		my @unselected = split(":",$unselected_string);

		for (@unselected) {
			$query = "delete from alias_aclgroup where aclgroup_id = '$gid' and alias_id = '$_';";
			$sth = $dbh->prepare($query);
			$sth->execute;
		}

		for (@selected) {
			$query = "select count(*) from alias_aclgroup where alias_id = '$_' and aclgroup_id = '$gid';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $count = $sth->fetchrow_hashref;
			unless($count->{'count'}){
				$query = "insert into alias_aclgroup(alias_id,aclgroup_id) values('$_','$gid');";
				$sth = $dbh->prepare($query);
				$sth->execute;
			} else {
				$error++;
			}
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
		}
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
