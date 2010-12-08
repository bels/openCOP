#!/usr/bin/env perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use Date::Manip;
use Data::Dumper;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $vars = $q->Vars;
	my $id = $vars->{'id'};

	my $ticket = {};
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select distinct(ticket) from audit where technician = ? or updater = ?;";
	my $sth = $dbh->prepare($query);
	$sth->execute($id,$id);
	my $results = $sth->fetchall_hashref('ticket');

	$query = "
		select
			*
		from
			audit
		where (
				technician = ?
			or
				updater = ?
		) and ticket  = ?;
	";
	my $sth = $dbh->prepare($query);
	foreach(keys %$results){
		$sth->execute($id,$id,$_);
		$ticket->{$_} = $sth->fetchall_hashref('record');
	}
	warn Dumper $ticket;

	print "Content-type: text/html\n\n";
	print qq(
		<table id="time_tracking_table">
			<thead>
				<tr class="header_row">
					<th class="header_cell">Status</th>
					<th class="header_cell">Updated</th>
					<th class="header_cell">Total Time</th>
				</tr>
			</thead>
			<tbody>
	);
	foreach my $t (sort { $a <=> $b } keys %$ticket){
	#	my @time;
	#	my @timediff;
	#	foreach my $r (sort { $a <=> $b } keys $ticket->{$t}){
	#		push(@time,$ticket->{$t}->{$r}->{'updated'});
	#	}
	#	for(my $i = 0; $i <= $#time; $i++){
	#		my $time = datediff($time[0], $time[1])
	#		push(@timediff,
	#	}
	#
	#	print qq(
	#		<tr class="body_row">
	#			<td class="body_cell"></td>
	#		</tr>
	#	);
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
