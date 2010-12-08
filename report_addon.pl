#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use UserFunctions;

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

if($authenticated == 1){
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $query = "select * from aclgroup where name != 'customers' and name != 'admins';";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $groups = $sth->fetchall_hashref('name');
	my @gid = sort( { lc($a) cmp lc($b) } keys %$groups);
	print "Content-type: text/html\n\n";
	for (my $i = 0; $i <= $#gid; $i++){
		print qq(<option value="$groups->{$gid[$i]}->{'id'}">$groups->{$gid[$i]}->{'name'}</option>);
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
