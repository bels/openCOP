#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'}, db_type => $config->{'db_type'});
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
	warn $data->{'section'};
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my %ticket_statuses = (1 => "New",2 => "In Progress",3 => "Waiting Customer",4 => "Waiting Vendor",5 => "Waiting Other",6 => "Closed", 7 => "Completed");
	my %priorities = (1 => "Low",2 =>"Normal",3 => "High",4=>"Business Critical");

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $user->get_user_id(alias => $alias);

	my $section = {};

	print "Content-type: text/html\n\n";

	$section->{$data->{'section'}} = $ticket->lookup(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data,section => $data->{'section'}, id => $id) or die "What?"; #need to pass in hashref named data
	if($section->{$data->{'section'}}->{'error'}) {
		warn "Access denied to section " .  $data->{'section'} . " for user $id";
	} else {
		warn $section->{$data->{'section'}};
		my @hash_order = (keys %{$section->{$data->{'section'}}});
		
		@hash_order = sort(@hash_order);
	
		print qq(
			<table class="ticket_summary">
				<thead>
					<tr class="header_row">
						<th class="ticket_number header_row_item">Ticket Number</th>
						<th class="ticket_status header_row_item">Ticket Status</th>
						<th class="ticket_contact header_row_item">Ticket Priority</th>
						<th class="ticket_contact header_row_item">Ticket Contact</th>
					</tr>
				</thead>
				<tbody>
		);
		foreach my $element (@hash_order){
			warn $section->{$data->{'section'}}->{$element};
		#this needs to vastly improve.  this displays the html inside of the ticket box.
			print qq(
					<tr class="lookup_row">
						<td class="row_ticket_number">$section->{$data->{'section'}}->{$element}->{'ticket'}</td>
						<td class="row_ticket_status">$ticket_statuses{$section->{$data->{'section'}}->{$element}->{'status'}}</td>
						<td class="row_ticket_priority">$priorities{$section->{$data->{'section'}}->{$element}->{'priority'}}</td>
						<td class="row_ticket_contact">$section->{$data->{'section'}}->{$element}->{'contact'}</td>
					</tr>
			);
		}
		print qq(
			</tbody>
			</table>
		);
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
