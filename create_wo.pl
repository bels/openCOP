#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use JSON;
use UserFunctions;
use URI::Escape;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user;
	my $alias;
	my $id;
	my $vars = $q->Vars;
	my $data;
	my $name = $vars->{'name'};
	$alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;

	my @tickets;
	my $object = from_json($vars->{'object'});
	shift(@{$object});

	my $step = 0;
	$query = "select count(*) from wo where name = ?;";
	$sth = $dbh->prepare($query);
	$sth->execute($name);
	my $result = $sth->fetchrow_hashref;

	print "Content-type: text/html\n\n";

	unless($result->{'count'}){
		$query = "select create_wo(?)";
		$sth = $dbh->prepare($query);
		$sth->execute($name);
		my $wo_id = $sth->fetchrow_hashref;

		foreach my $i (@{$object}){
			foreach my $j (@{$i}){
					foreach (keys %$j){
						$j->{$_} =~ s/\+/ /g;
						$j->{$_} = uri_unescape($j->{$_});
						$data->{$_} = $j->{$_};
						if($data->{$_} eq ""){
							$data->{$_} = "0";
						}
					}
			}
			$step++;
	
			$query = "select insert_wo(
				?,
				?,
				?,
				?,
				?
			)";
			$sth = $dbh->prepare($query);
			$sth->execute($wo_id->{'create_wo'},$data->{'section'},$data->{'requires'},$step,$data->{'problem'});
		}
		print "0";
	} else {
		print "1";
		print "A work order with that name already exists. Please choose a new name.";
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
