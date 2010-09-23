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
	my $data = $q->Vars;
	my $results = $ticket->lookup(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data); #need to pass in hashref named data
	print "Content-type: text/html\n\n";

	my @hash_order = keys %$results;
	
	@hash_order = sort(@hash_order);
	
	foreach my $element (@hash_order)
	{
		#this needs to vastly improve.  this displays the html inside of the ticket box.
		print "<div class=\"lookup_row\"><div class=\"row_ticket_number\">$results->{$element}->{'ticket'}</div><div class=\"row_ticket_status\">$results->{$element}->{'status'}</div><div class=\"row_ticket_contact\">$results->{$element}->{'contact'}</div></div>";
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}