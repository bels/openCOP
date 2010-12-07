#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use Ticket;
use Data::Dumper;
use URI::Escape;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $data = $q->Vars;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my @placeholders = ($id,$id);
	#This part will build the where clause to search all columns of the same datatype as the data passed in from the search box
	my $query;
	my $sth;
	my $section = {};

	print "Content-type: text/html\n\n";

	$query = "select id,name from section;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');
	$data->{'section'} = "critical";
		$query = "
			select
				helpdesk.ticket as ticket,
				users.alias,
				section.name as name,
				status.status as status,
				priority.description as priority,
				helpdesk.contact as contact
			from
				helpdesk
				join
					section on section.id = helpdesk.section
				left outer join
					troubleshooting on troubleshooting.ticket_id = helpdesk.ticket
				left outer join
					notes on notes.ticket_id = helpdesk.ticket
				join
					users on users.id = helpdesk.technician
				left outer join
					site on site.id = helpdesk.site
				join
					priority on priority.severity = helpdesk.priority
				join
					status on status.id = helpdesk.status
			where (
				(
					helpdesk.status not in ('6','7')
				) and (
					helpdesk.active
				) and (
					helpdesk.priority > '2'
				) and (
					helpdesk.technician = ?
					or (
						select
							bool_or(section_aclgroup.aclread) as read
						from
							section_aclgroup
							join
								section on section.id = section_aclgroup.section_id
							join
								aclgroup on aclgroup.id = section_aclgroup.aclgroup_id
						where (
							section_aclgroup.aclgroup_id in (
								select
									aclgroup_id
								from
									alias_aclgroup
								where
									alias_id = ?
							)
						)
					)
				)
			)
			order by ticket;
		";
		$sth = $dbh->prepare($query);
		$sth->execute(@placeholders);
		$section->{$data->{'section'}} = $sth->fetchall_hashref('ticket');
		warn Dumper $section;
	if($section->{$data->{'section'}}->{'error'}) {
		warn "Access denied to section " .  $data->{'section'} . " for user $id";
	} else {
		my @hash_order = (keys %{$section->{$data->{'section'}}});
		
		@hash_order = sort({$a <=> $b } @hash_order);
	
		print qq(
			<link rel="stylesheet" href="styles/current_critical.css" type="text/css" media="screen">
			<script type="text/javascript" src="javascripts/jquery.tablesorter.js"></script>
			<script type="text/javascript" src="javascripts/current_critical.js"></script>

			<table class="ticket_summary">
				<thead>
					<tr class="header_row">
						<th class="ticket_number header_row_item">Ticket Number</th>
						<th class="ticket_status header_row_item">Ticket Status</th>
						<th class="ticket_priority header_row_item">Ticket Priority</th>
						<th class="ticket_contact header_row_item">Ticket Contact</th>
						<th class="ticket_technician header_row_item">Assigned Technician</th>
						<th class="ticket_section header_row_item">Section</th>
					</tr>
				</thead>
				<tbody>
		);
		foreach my $element (@hash_order){
		#this needs to vastly improve.  this displays the html inside of the ticket box.
				print qq(
						<tr class="lookup_row">
							<td class="row_ticket_number">$section->{$data->{'section'}}->{$element}->{'ticket'}</td>
							<td class="row_ticket_status">$section->{$data->{'section'}}->{$element}->{'status'}</td>
							<td class="row_ticket_priority">$section->{$data->{'section'}}->{$element}->{'priority'}</td>
							<td class="row_ticket_contact">$section->{$data->{'section'}}->{$element}->{'contact'}</td>
							<td class="row_ticket_technician">$section->{$data->{'section'}}->{$element}->{'alias'}</td>
							<td class="row_ticket_section">$section->{$data->{'section'}}->{$element}->{'name'}</td>
						</tr>
				);
		}
		print qq(
			</tbody>
			</table>
			<div id="ticket_details">
			</div>
			<div id="behind_popup">
			</div>
		);
	}
}
else{
	print $q->redirect(-URL => $config->{'index_page'});
}
