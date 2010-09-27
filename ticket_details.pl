#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $ticket_number = $q->param("ticket_number");
	my $results = $ticket->details(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $ticket_number); #need to pass in hashref named data
	print "Content-type: text/html\n\n";

	my %ticket_statuses = (1 => "New",2 => "In Progress",3 => "Waiting Customer",4 => "Waiting Vendor",5 => "Waiting Other",5 => "Closed", 6 => "Completed"); 
	my %priorities = (0 => "Low",1 =>"Normal",2 => "High",3=>"Business Critical");

	print  qq(<form action="update_ticket.pl" method="POST"><input type="hidden" name="ticket_number" value="$results->{'ticket'}"><label for="priority">Priority:</label><span id="priority" name="priority">$priorities{$results->{'priority'}}</span><br/>
		<label for="ticket_number">Ticket Number:</label><span id="ticket_number" name="ticket_number">$results->{'ticket'}</span><label for="author">Author:</label><span id="author" name="author">$results->{'author'}</span><label for="contact">Contact:</label><input type="text" id="contact" name="contact" value="$results->{'contact'}"><label for="contact_phone">Contact Phone:</label><input type="text" id="contact_phone" name="contact_phone" value="$results->{'contact_phone'}"><label for="contact_email">Contact Email:</label><input type="text" id="contact_email" name="contact_email" value="$results->{'contact_email'}"><br/>
		<label for="status">Ticket Status:<span id="status" name="status">$ticket_statuses{$results->{'status'}}</span><label for="site">Site:</label><input type="text" id="site" name="site" value="$results->{'site'}"><label for="location">Location:</label><input type="text" id="location" name="location" value="$results->{'location'}"><label for="requested_on">Requested On:</label><span id="requeseted_on" name="requested_on">$results->{'requested'}</span><label for="last_updated">Last Updated:</label><span id="last_updated" name="last_updated">$results->{'updated'}</span><br/>
		<label for="problem">Problem:</label><span id="problem" name="problem">$results->{'problem'}</span><br/>
		<label for="troubleshoot">Troubleshooting Tried:</label><textarea cols="80" rows="10" id="troubleshooting" name="troubleshooting">$results->{'troubleshot'}</textarea><br/>
		<label for="notes">Notes:</label><textarea rows="10" cols="80" id="notes" name="notes">$results->{'notes'}</textarea><br/>
		<input type="submit" value="Update">
	);
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}