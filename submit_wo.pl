#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use JSON;
use URI::Escape;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	my $data = $q->Vars;

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;

	$query = "select * from wo_template where wo_id = ?;";
	$sth = $dbh->prepare($query);
	$sth->execute($data->{'wo'});
	my $wo_list = $sth->fetchall_hashref('step');

	$data->{'submitter'} = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $access;

	$query = "
		insert into wo(
			active
		) values (
			true
		);";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$query = "select last_value from wo_id_seq";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $wo_number = $sth->fetchrow_hashref;
	foreach(keys %$wo_list){
		$data->{'section'} = $wo_list->{$_}->{'section_id'};
		$data->{'problem'} = $wo_list->{$_}->{'problem'};

		$access = $ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data) or die "Access denied to section $data->{'section'} for user  $data->{'submitter'}"; #need to pass in hashref named data
		unless($access->{'error'}){
			$wo_list->{$_}->{'ticket'} = $access->{'id'};
		}
	}
	foreach(keys %$wo_list){
		if($wo_list->{$_}->{'requires_id'}){
			$query = "
				select
					ticket
				from
					helpdesk
				where
					section = '$wo_list->{$wo_list->{$_}->{'requires_id'}}->{'section_id'}'
				and
					ticket in (";
			foreach(keys %$wo_list){
				unless($wo_list->{$_}->{'ticket'} == ""){
					$query .= "'$wo_list->{$_}->{'ticket'}',";
				}
			}
			$query =~ s/,$//;
			$query .= ");";
			warn $query;
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $ticket = $sth->fetchrow_hashref;
			$wo_list->{$_}->{'requires'} = $ticket->{'ticket'};
		} else {
			$wo_list->{$_}->{'requires'} = 0;
		}

		$query = "
			insert into wo_ticket (
				ticket_id,
				requires,
				wo_id,
				step
			) values (
				'$wo_list->{$_}->{'ticket'}',
				'$wo_list->{$_}->{'requires'}',
				'$wo_number->{'last_value'}',
				'$wo_list->{$_}->{'step'}'
			);
		";
		$sth = $dbh->prepare($query);
		$sth->execute;
		if($wo_list->{$_}->{'requires'}){
			$query = "update helpdesk set active = false where ticket = ?;";
			$sth = $dbh->prepare($query);
			$sth->execute($wo_list->{$_}->{'ticket'});
		}
		
		
	}

	print "Content-type: text/html\n\n";
	print "0";
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
