#!/usr/local/bin/perl

use strict;
use lib './libs';
use CGI;
use SessionFunctions;
use ReadConfig;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in customer_ticket_lookup.pl";
	my $ticket_number = $q->param('ticket_number');
	my $query = "select * from helpdesk where ticket = '$ticket_number'";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchrow_hashref;
	$query = "select * from notes where tkid = '$ticket_number' ORDER BY nid DESC";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $notes = $sth->fetchall_arrayref;
	print "Content-type: text/html\n\n";

	my %ticket_statuses = (1 => "New",2 => "In Progress",3 => "Waiting Customer",4 => "Waiting Vendor",5 => "Waiting Other",6 => "Closed", 7 => "Completed");
	my %priorities = (1 => "Low",2 =>"Normal",3 => "High",4=>"Business Critical");
	
	print "<div class=\"ticket_details\"><label>Ticket Contact:</label>$results->{'contact'}<br /><label>Ticket Number:</label>$results->{'ticket'}<br /><label>Ticket Status:</label>$ticket_statuses{$results->{'status'}}<br /><label>Ticket Priority:</label>$priorities{$results->{'priority'}}<br />";
	print qq(<form id="add_notes_form"><input type="hidden" name="tkid" id="tkid" value=$ticket_number><label for="new_note">Update your ticket</label><br /><textarea id="new_note" name="new_note" cols="80" rows="5"></textarea><br /><button type="button" id="update_ticket_button">Update</button><br />);
	print qq(<h4>Previous Notes</h4>);
	my $zebra = "even";
	foreach my $note (@$notes)
	{
		if ($zebra eq "even"){
			$zebra = "odd";
		} elsif ($zebra eq "odd") {
			$zebra = "even";
		}
		print qq(<div class="note_div $zebra"><span class="note_date">);
		print substr(@$note[3],0,19);
		print qq(: </span><span class="note">@$note[2]</span></div>);
	}
	print "</div>";
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
