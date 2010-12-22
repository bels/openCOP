#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;
	my $data;

	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "add_group"){
		my $groupname = $vars->{'groupname'};
		$groupname =~ s/\'/\'\'/g;
		my $error = 0;

		$query = "select count(*) from aclgroup where name = '$groupname';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $count = $sth->fetchrow_hashref;
		unless($count->{'count'}){
			$query = "insert into aclgroup (name) values ('$groupname');";
			$sth = $dbh->prepare($query);
			$sth->execute or $error = 2;
		} else {
			$error = 1;
		}

		print "Content-type: text/html\n\n";
		print $error;
	} elsif ($vars->{'mode'} eq "del_group"){
		my $group = $vars->{'group'};
		my $error = 0;

		$query = "select count(*) from aclgroup where id = '$group';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $count = $sth->fetchrow_hashref;
		if($count->{'count'}){
			$query = "delete from aclgroup where id = '$group';";
			$sth = $dbh->prepare($query);
			$sth->execute or $error = 2;
		} else {
			$error = 1;
		}

		print "Content-type: text/html\n\n";
		print $error;
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this!";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
