#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	my $i;
	my @pid;

	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "init_ug"){
		my $ig_again = {};
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		my $id = $vars->{'uid'};
		$in_groups = $user->get_groups(id => $id);

		$query = "select * from aclgroup;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_groups  = $sth->fetchall_hashref('name');
		my @in_groups;
	
		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="ug_select_array[]">
		);
	
		if(defined($in_groups)){
			foreach (keys %$in_groups){
				push(@in_groups,$in_groups->{$_}->{'name'});
				$ig_again->{$in_groups->{$_}->{'name'}} = {
					'name'		=>	$in_groups->{$_}->{'name'},
					'aclgroup_id'	=>	$in_groups->{$_}->{'aclgroup_id'},
				};
			}
		}
		my @sig = sort( {lc($a) cmp lc($b) } @in_groups);
		for ($i = 0; $i <= $#sig; $i++){
			$data .= qq(<option selected="selected" value="$ig_again->{$sig[$i]}->{'aclgroup_id'}">$ig_again->{$sig[$i]}->{'name'}</option>);
		}

		foreach (keys %$all_groups){
			foreach (@in_groups){
				if($_ =~ m/$all_groups->{$_}->{'name'}/) {
					delete($all_groups->{$_});
				}
			}
			if(defined($all_groups->{$_})){
				push(@pid,$all_groups->{$_}->{'name'});
			}
		}
		my @gid = sort( {lc($a) cmp lc($b) } @pid);
		for ($i = 0; $i <= $#gid; $i++){
			$data .= qq(<option value="$all_groups->{$gid[$i]}->{'id'}">$all_groups->{$gid[$i]}->{'name'}</option>);
		}
	
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "init_gu"){
		my $iu_again = {};
		my $id = $vars->{'gid'};
		my $query = "select distinct(alias_aclgroup.alias_id),alias from alias_aclgroup join users on alias_aclgroup.alias_id = users.id where (aclgroup_id = '$id');";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$in_users = $sth->fetchall_hashref('alias_id');

		$query = "select id,alias from users where active = true;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_users  = $sth->fetchall_hashref('alias');
		my @in_users;
	
		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="gu_select_array[]">
		);
	
		if(defined($in_users)){
			foreach (keys %$in_users){
				push(@in_users,$in_users->{$_}->{'alias'});
				$iu_again->{$in_users->{$_}->{'alias'}} = {
					'alias'		=>	$in_users->{$_}->{'alias'},
					'alias_id'	=>	$in_users->{$_}->{'alias_id'},
				};
			}
		}
		my @siu = sort( {lc($a) cmp lc($b) } @in_users);
		for ($i = 0; $i <= $#siu; $i++){
			$data .= qq(<option selected="selected" value="$iu_again->{$siu[$i]}->{'alias_id'}">$iu_again->{$siu[$i]}->{'alias'}</option>);
		}

		foreach (keys %$all_users){
			foreach (@in_users){
				if($_ =~ m/$all_users->{$_}->{'alias'}/) {
					delete($all_users->{$_});
				}
			}
			if(defined($all_users->{$_})){
				push(@pid,$all_users->{$_}->{'alias'});
			}
		}
		my @uid = sort( {lc($a) cmp lc($b) } @pid);
		for ($i = 0; $i <= $#uid; $i++){	
			$data .= qq(<option value="$all_users->{$uid[$i]}->{'id'}">$all_users->{$uid[$i]}->{'alias'}</option>);
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
