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

	print  qq(<label for="priority">Priority:</label><span id="priority" name="priority">$priorities{$results->{'priority'}}</span><br/>
		<label for="ticket_number">Ticket Number:</label><span id="ticket_number" name="ticket_number">$results->{'ticket'}</span><label for="author">Author:</label><span id="author" name="author">$results->{'author'}</span><label for="contact">Contact:</label><span id="contact" name="contact">$results->{'contact'}</span><label for="contact_phone">Contact Phone:</label><span id="contact_phone" name="contact_phone">$results->{'contact_phone'}</span><br/>
		<label for="status">Ticket Status:<span id="status" name="status">$ticket_statuses{$results->{'status'}}</span><label for="site">Site:</label><span id="site" name="site">$results->{'site'}</span><label for="location">Location:</label><span id="location" name="location">$results->{'location'}</span><label for="requested_on"><span id="requeseted_on" name="requested_on">$results->{'requested'}</span><label for="last_updated">Last Updated:</label><span id="last_updated" name="last_updated">$results->{'updated'}</span><br/>
		
	);
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}