#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use Template;
use SessionFunctions;

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
	my $vars = $q->Vars;
	my $wo_number = $vars->{'wo'};
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query = "select * from wo_ticket where wo_id = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($wo_number);
	my $wo = $sth->fetchall_hashref('id');
	print qq(
		<table class="wo_summary">
			<thead>
				<tr class="header_row">
					<th class="ticket_number header_row_item">Ticket Number</th>
					<th class="step_number header_row_item">Step Number</th>
					<th class="assigned_tech header_row_item">Assigned Technician</th>
					<th class="ticket_status header_row_item">Ticket Status</th>
					<th class="ticket_section header_row_item">Section</th>
				</tr>
			</thead>
			<tbody>
	);

	$query = "
		select
			helpdesk.ticket,
			helpdesk.active,
			users.alias as technician,
			status.status as status,
			section.name as section
			
		from
			helpdesk
		join
			status on status.id = helpdesk.status
		join
			section on section.id = helpdesk.section
		join
			users on users.id = helpdesk.technician
		where
			ticket = ?
		;
	";
	$sth = $dbh->prepare($query);
	foreach(keys %$wo){
		$sth->execute($wo->{$_}->{'ticket_id'});
		my $ticket = $sth->fetchrow_hashref;
		print qq(
			<tr class="lookup_row
		);
		warn $ticket->{'active'};
		unless($ticket->{'active'}){
			print qq( disabled);
		}
		print qq(">
				<td class="row_ticket_number">$wo->{$_}->{'ticket_id'}</td>
				<td class="row_step_number">$wo->{$_}->{'step'}</td>
				<td class="row_assigned_tech">$ticket->{'technician'}</td>
				<td class="row_ticket_status">$ticket->{'status'}</td>
				<td class="row_ticket_section">$ticket->{'section'}</td>
			</tr>
		);
	}
	print qq(
		</tbody>
		</table>
	);

}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
