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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;
	my $data;

	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "add_gs"){
		my $gid = $vars->{'gid'};
		my $sid = $vars->{'sid'};
		my $permission_string = $vars->{'permission'};
		my $error = 0;

		for($permission_string){
			$_ =~ s/:$//;
		}

		my @permission = split(":",$permission_string);

		$query = "select count(*) from section_aclgroup where section_id = '$sid' and aclgroup_id = '$gid';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $count = $sth->fetchrow_hashref;
		unless($count->{'count'}){
			$query = "insert into section_aclgroup(section_id,aclgroup_id,aclread,aclcreate,aclupdate,aclcomplete) values('$sid','$gid','$permission[0]','$permission[1]','$permission[2]','$permission[3]');";
			$sth = $dbh->prepare($query);
			$sth->execute;
		} else {
			$error = 1;
		}

		print "Content-type: text/html\n\n";
		print $error;
	} elsif($vars->{'mode'} eq "delete_permission"){
		my $id = $vars->{'id'};
		my $error = 0;
		$query = "delete from section_aclgroup where id = '$id';";
		$sth = $dbh->prepare($query);
		$sth->execute or $error = 1;
		print "Content-type: text/html\n\n";
		print $error;
	} elsif($vars->{'mode'} eq "update_permission"){
		my $id = $vars->{'id'};
		my $permission_string = $vars->{'permission'};
		my $error = 0;
		for($permission_string){
			$_ =~ s/:$//;
		}

		my @permission = split(":",$permission_string);

		$query = "update section_aclgroup set aclread = '$permission[0]', aclcreate = '$permission[1]', aclupdate = '$permission[2]', aclcomplete = '$permission[3]' where id = '$id';";
		$sth = $dbh->prepare($query);
		$sth->execute or $error = 1;
		print "Content-type: text/html\n\n";
		print $error;
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this!";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
