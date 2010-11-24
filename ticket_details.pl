#!/usr/bin/env perl

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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query;
	my $sth;

	my $ticket_number = $q->param("ticket_number");
	my $results = $ticket->details(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $ticket_number); #need to pass in hashref named data
	print "Content-type: text/html\n\n";

	# Get the list of available statuses
	$query = "select * from status;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $status_list = $sth->fetchall_hashref('id');

	# Get the list of available priorities
	$query = "select * from priority;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $priority_list = $sth->fetchall_hashref('id');


	my $site;
	my $site_id = $results->{'site'};

	if(defined($site_id)){
		$query = "select * from site where id = '$site_id'";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $stuff = $sth->fetchrow_hashref;
		$site = $stuff->{'name'};
	} else {
		$site = "";
	}

	$query = "select * from troubleshooting where ticket_id = '$ticket_number'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $troubleshooting = $sth->fetchall_hashref('id');

	$query = "select * from section;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');

	$query = "select * from notes where ticket_id = '$ticket_number'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $notes = $sth->fetchall_hashref('id');

	$results->{'free_time'} = substr($results->{'free_time'},0,8);

	print qq(<h2>Ticket Details</h2>);
	print qq(
		<form action="update_ticket.pl" method="POST" id="update_form">
			<input type="hidden" name="tech" value="1">
			<input type="hidden" name="section" value="$section_list->{$results->{'section'}}->{'id'}">
			<input type="hidden" name="ticket_number" value="$results->{'ticket'}">
			<label for="priority">Priority:</label><span id="priority" name="priority">$priority_list->{$results->{'priority'}}->{'description'}</span>
		);
	print qq(
		<br>
		<label for="section">Section:</label><span id="section" name="section">$section_list->{$results->{'section'}}->{'name'}</span>
		<br>
		<label for="status">Ticket Status:</label><select id="status" name="status">
	);
	my $i;
	for ($i = 1; $i <= keys(%$status_list); $i++)
	{
		print qq(<option value=$i);
		if($results->{'status'} == $i){ print " selected"};
		print qq(>$status_list->{$i}->{'status'}</option>);
	}

	print qq(</select>);
	print qq(
		<br>
		<label for="ticket_number">Ticket Number:</label><span id="ticket_number" name="ticket_number">$results->{'ticket'}</span>
		<label for="author">Author:</label><span id="author" name="author">$results->{'author'}</span>
		<br>
		<label for="contact">Contact:</label><input type="text" id="contact" name="contact" value="$results->{'contact'}">
		<label for="contact_phone">Contact Phone:</label><input type="text" id="contact_phone" name="contact_phone" value="$results->{'contact_phone'}">
		<label for="contact_email">Contact Email:</label><input type="text" id="contact_email" name="contact_email" value="$results->{'contact_email'}">
		<br>
		<label for="site">Site:</label><input type="text" id="site" name="site" value="$site">
		<label for="location">Location:</label><input type="text" id="location" name="location" value="$results->{'location'}">
		<br>
		<label for="free">Free:</label><span id="free" name="free">$results->{'free_date'} 
	);
	print substr($results->{'free_time'},0,5);
	print qq(
		</span>
		<br>
		<label for="requested_on">Requested On:</label><span id="requested_on" name="requested_on">
	);
	print substr($results->{'requested'},0,16);
	print qq(</span><label for="last_updated">Last Updated:</label><span id="last_updated" name="last_updated">);
	print substr($results->{'updated'},0,16);
	print qq(
		</span>
		<br>
		<label for="problem">Problem:</label><div id="problem" name="problem">$results->{'problem'}</div><br>
		<label for="troubleshoot">Troubleshooting Tried:</label><textarea cols="80" rows="8" id="troubleshooting" name="troubleshooting"></textarea><br>
		<label for="past_troubleshoot">Past Troubleshooting:</label><div id="past_troubleshoot" name="past_troubleshoot"><br>
	);
	
	my @hash_order = keys %$troubleshooting;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print $troubleshooting->{$t}->{'performed'} . "<br />";
		print $troubleshooting->{$t}->{'troubleshooting'} . "<br />";
	}
	
	print qq(</div><br />
		<label for="notes">Notes:</label><textarea rows="8" cols="80" id="notes" name="notes"></textarea><br/>
	);

	print qq(<label for="past_notes">Past Notes:</label><div id="past_notes" name="past_notes">);
	@hash_order = keys %$notes;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print $notes->{$t}->{'performed'} . "<br />";
		print $notes->{$t}->{'note'} . "<br />";
	}
	print qq(</div><br />
		<input type="submit" value="Update">
	);
	
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
