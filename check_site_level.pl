#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use URI::Escape;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $vars = $q->Vars;
	my $query;
	my $sth;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1}) or die "Database connection failed in $0";

	$query = "select count(*) from site where level = ?";
	$sth = $dbh->prepare($query);
        $sth->execute($vars->{'site'});
	my $count = $sth->fetchrow_hashref;

	if($count->{'count'}){
		$query = "select * from site where level = ?";
	        $sth = $dbh->prepare($query);
	        $sth->execute($vars->{'site'});
		my $sites = $sth->fetchall_hashref('id');
		my $data = qq(Deleting this site level will remove the following sites. Are you sure you want to proceed? );
		foreach (keys %$sites){
			$data .= "<br>$sites->{$_}->{'name'}";
		}
		print "Content-type: text/html\n\n";
		print "1";
		print $data;
		warn $data;
	} else {
		print "Content-type: text/html\n\n";
		print "0";
	}
} elsif($authenticated == 2){
        print $q->redirect(-URL => $config->{'index_page'})
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
