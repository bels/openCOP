#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use DBI;
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

	my %ticket_statuses = (1 => "New",2 => "In Progress",3 => "Waiting Customer",4 => "Waiting Vendor",5 => "Waiting Other",6 => "Closed", 7 => "Completed"); 
	my %priorities = (1 => "Low",2 =>"Normal",3 => "High",4=>"Business Critical");

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in add_sites.pl";
	my $site_id = $results->{'site'};
	my $query = "select * from site where scid = '$site_id'";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $stuff = $sth->fetchrow_hashref;
	my $site = $stuff->{'name'};

	$query = "select * from troubleshooting where tkid = '$ticket_number'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $troubleshooting = $sth->fetchall_hashref('tid');
	$query = "select * from notes where tkid = '$ticket_number'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $notes = $sth->fetchall_hashref('nid');
	print qq(<h2>Ticket Details</h2>);
	print qq(<form action="update_ticket.pl" method="POST" id="update_form"><input type="hidden" name="ticket_number" value="$results->{'ticket'}"><label for="priority">Priority:</label><span id="priority" name="priority">$priorities{$results->{'priority'}}</span>);
	print qq(<label for="status">Ticket Status:</label><select id="status" name="status">);
	my $i;
	for ($i = 1; $i <= keys(%ticket_statuses); $i++)
	{
		print qq(<option value=$i);
		if($results->{'status'} == $i){ print " selected"};
		print qq(>$ticket_statuses{$i}</option>);
	}	
	print qq(</select>);
	print qq(<br/><label for="ticket_number">Ticket Number:</label><span id="ticket_number" name="ticket_number">$results->{'ticket'}</span><label for="author">Author:</label><span id="author" name="author">$results->{'author'}</span><br/>
		<label for="contact">Contact:</label><input type="text" id="contact" name="contact" value="$results->{'contact'}"><label for="contact_phone">Contact Phone:</label><input type="text" id="contact_phone" name="contact_phone" value="$results->{'contact_phone'}"><label for="contact_email">Contact Email:</label><input type="text" id="contact_email" name="contact_email" value="$results->{'contact_email'}"><br/>
		<label for="site">Site:</label><input type="text" id="site" name="site" value="$site"><label for="location">Location:</label><input type="text" id="location" name="location" value="$results->{'location'}"><br/>
		<label for="requested_on">Requested On:</label><span id="requeseted_on" name="requested_on">);
	print substr($results->{'requested'},0,19);
	print qq(</span><label for="last_updated">Last Updated:</label><span id="last_updated" name="last_updated">);
	print substr($results->{'updated'},0,19);
	print qq(</span><br/>
		<label for="problem">Problem:</label><span id="problem" name="problem">$results->{'problem'}</span><br/>
		<label for="troubleshoot">Troubleshooting Tried:</label><textarea cols="80" rows="8" id="troubleshooting" name="troubleshooting"></textarea><br/>
		<label for="past_troubleshoot">Past Troubleshooting:</label><span id="past_troubleshoot" name="past_troubleshoot">);
	
	my @hash_order = keys %$troubleshooting;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print $troubleshooting->{$t}->{'performed'} . "<br />";
		print $troubleshooting->{$t}->{'troubleshooting'} . "<br />";
	}
	
	print qq(</span><br />
		<label for="notes">Notes:</label><textarea rows="8" cols="80" id="notes" name="notes"></textarea><br/>);

	print qq(<label for="past_notes">Past Notes:</label><span id="past_notes" name="past_notes">);
	@hash_order = keys %$notes;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print $notes->{$t}->{'performed'} . "<br />";
		print $notes->{$t}->{'note'} . "<br />";
	}
	print qq(</span><br />
		<input type="submit" value="Update">);
	
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}