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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;

	if($vars->{'mode'} eq "configure"){
		if($vars->{'action'} =~ m/add/){
			$query = "select $vars->{'type'} from $vars->{'type'} where $vars->{'type'} ilike '$vars->{'value'}';";
			$sth = $dbh->prepare($query) or die "Could not prepare query in $0";
			$sth->execute;
			my $result = $sth->fetchrow_hashref;
			if (!$result->{$vars->{'type'}}) {
				$vars->{'value'} =~ s/'/''/g;
				$query = "insert into $vars->{'type'}($vars->{'type'}) values('$vars->{'value'}');";
				$sth = $dbh->prepare($query) or die "Could not prepare query in $0";
				$sth->execute;
				print "Content-type: text/html\n\n";
				print "0";
			} else {
				print "Content-type: text/html\n\n";
				print "1";
			}
		} elsif($vars->{'action'} =~ m/del/){
			warn $vars->{'type'};
			warn $vars->{'value'};
			my $id;
			if($vars->{'type'} eq "template"){
				$id = "id";
			} elsif($vars->{'type'} eq "property"){
				$id = "id";
			}
			$query = "select $vars->{'type'} from $vars->{'type'} where $id = '$vars->{'value'}';";
			warn $query;
			$sth = $dbh->prepare($query) or die "Could not prepare query in $0";
			$sth->execute;
			my $result = $sth->fetchrow_hashref;
			if ($result->{$vars->{'type'}}) {
				$query = "delete from $vars->{'type'} where $id = '$vars->{'value'}';";
			warn $query;
				$sth = $dbh->prepare($query) or die "Could not prepare query in $0";
				$sth->execute;
				print "Content-type: text/html\n\n";
				print "0";
			} else {
				print "Content-type: text/html\n\n";
				print "2";
			}
		}
	}
}

else
{
	print $q->redirect(-URL => $config->{'index_page'});
}

