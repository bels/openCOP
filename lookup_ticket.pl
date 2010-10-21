#!/usr/bin/env perl

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
	my $data = $q->Vars;
	
	my $uid = $session->get_name_for_session(auth_table => $config->{'auth_table'},sid => $cookie{'sid'});

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in lookup_ticket.pl";
	my $query = "select sections from users where alias = '$uid'";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchrow_hashref;
	$query = "select sid from section where name = '$results->{'sections'}'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	$results = $sth->fetchrow_hashref;
	my $section = $results->{'sid'};
	my $results = $ticket->lookup(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data,section => $section); #need to pass in hashref named data
	print "Content-type: text/html\n\n";

	my @hash_order = keys %$results;
	
	@hash_order = sort(@hash_order);
	
	my %ticket_statuses = (1 => "New",2 => "In Progress",3 => "Waiting Customer",4 => "Waiting Vendor",5 => "Waiting Other",6 => "Closed", 7 => "Completed");
	my %priorities = (1 => "Low",2 =>"Normal",3 => "High",4=>"Business Critical");
	print qq(<table id="ticket_summary"><thead><tr id="header_row"><th id="ticket_number" class="header_row_item">Ticket Number</th><th id="ticket_status" class="header_row_item">Ticket Status</th><th id="ticket_contact" class="header_row_item">Ticket Priority</th><th id="ticket_contact" class="header_row_item">Ticket Contact</th></tr></thead><tbody>);
	foreach my $element (@hash_order)
	{
		#this needs to vastly improve.  this displays the html inside of the ticket box.
		print "<tr class=\"lookup_row\"><td class=\"row_ticket_number\">$results->{$element}->{'ticket'}</td><td class=\"row_ticket_status\">$ticket_statuses{$results->{$element}->{'status'}}</td><td class=\"row_ticket_priority\">$priorities{$results->{$element}->{'priority'}}</td><td class=\"row_ticket_contact\">$results->{$element}->{'contact'}</td></tr>";
	}
	print qq(</tbody></table>);
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}