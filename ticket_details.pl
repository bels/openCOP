#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use DBI;
use SessionFunctions;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

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

	#Sanitizing data retrieved from the database
	foreach my $key (keys %$results){
		$results->{$key} =~ s/\'\'/\'/g;
	}

	# Get the list of available technicians
	$query = "select * from users join alias_aclgroup on users.id = alias_aclgroup.alias_id where active and aclgroup_id != (select id from aclgroup where name = 'customers')";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $tech_list = $sth->fetchall_hashref('id');

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

	$query = "select id,name from section where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');

	$query = "select * from notes where ticket_id = '$ticket_number'";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $notes = $sth->fetchall_hashref('id');

	$results->{'start_time'} = substr($results->{'start_time'},0,8);
	$results->{'end_time'} = substr($results->{'end_time'},0,8);

	print qq(<form action="update_ticket.pl" method="POST" id="update_form"><div id="details_wrapper"><div class="form_title">Ticket Details</div>);
	print qq(
		
			<input type="hidden" name="tech" value="1">
			<input type="hidden" name="section" value="$section_list->{$results->{'section'}}->{'id'}">
			<input type="hidden" name="ticket_number" value="$results->{'ticket'}">
			<label for="ticket_number">Ticket Number:</label><span id="ticket_number" name="ticket_number">$results->{'ticket'}</span>
			<label for="priority">Priority:</label>
	);
	if($user->is_admin(id => $id)){
		print qq(
			<select id="priority" name="priority" class="styled_form_element">
		);
		for (my $i = 1; $i <= keys(%$priority_list); $i++){
			print qq(<option value="$i");
			if($results->{'priority'} == $i){ print " selected"};
			print qq(>$priority_list->{$i}->{'description'}</option>);
		}
		print qq(</select>);
	} else {
		print qq(<span id="priority" name="priority">$priority_list->{$results->{'priority'}}->{'description'}</span>);
	}
	print qq(
			<label for="author">Author:</label><span id="author" name="author">$results->{'author'}</span>
	);
	print qq(
		<br>
		<label for="section">Section:</label>
	);
	if($user->is_admin(id => $id)){
		print qq(
			<select id="update_section" name="update_section" class="styled_form_element">
		);
		foreach(keys(%$section_list)){
			print qq(<option value="$_");
			if($results->{'section'} == $_){ print " selected"};
			print qq(>$section_list->{$_}->{'name'}</option>);
		}
		print qq(</select>);
	} else {
		print qq(
			<span id="section" name="section">$section_list->{$results->{'section'}}->{'name'}</span>
		);
	}
	print qq(
		<br>
		<label for="status">Ticket Status:</label><select id="status" name="status"  class="styled_form_element">
	);
	for (my $i = 1; $i <= keys(%$status_list); $i++)
	{
		print qq(<option value=$i);
		if($results->{'status'} == $i){ print " selected"};
		print qq(>$status_list->{$i}->{'status'}</option>);
	}

	print qq(</select>);
	print qq(
		<br>
		<label for="contact">Contact:</label><input type="text" id="contact" name="contact" value="$results->{'contact'}" class="styled_form_element">
		<label for="contact_phone">Contact Phone:</label><input type="text" id="contact_phone" name="contact_phone" value="$results->{'contact_phone'}" class="styled_form_element">
		<label for="contact_email">Contact Email:</label><input type="text" id="contact_email" name="contact_email" value="$results->{'contact_email'}" class="styled_form_element">
		<br>
		<label for="site">Site:</label><input type="text" id="site" name="site" value="$site" class="styled_form_element">
		<label for="location">Location:</label><input type="text" id="location" name="location" value="$results->{'location'}" class="styled_form_element">
		<label for="technician">Technician:</label>
	);
	if($user->is_admin(id => $id)){
		print qq(
			<select id="technician" name="technician" class="styled_form_element">
		);
		for (my $i = 1; $i <= keys(%$tech_list); $i++){
			print qq(<option value="$i");
			if($results->{'technician'} == $i){ print " selected"};
			print qq(>$tech_list->{$i}->{'alias'}</option>);
		}
		print qq(</select>);
	} else {
		print qq(<span id="technician" name="technician">$tech_list->{$results->{'technician'}}->{'alias'}</span>);
	}
	print qq(
		<br>
		<label for="free">Free:</label><span id="free" name="free">$results->{'free_date'} 
	);
	print substr($results->{'start_time'},0,5) . " - " . substr($results->{'end_time'},0,5);
	print qq(
		</span>
		<br>
		<label for="requested_on">Requested On:</label><span id="requested_on" name="requested_on">);
	print substr($results->{'requested'},0,16);
	print qq(</span><label for="last_updated">Last Updated:</label><span id="last_updated" name="last_updated">);
	print substr($results->{'updated'},0,16);
	print qq(
		</span>
	</div>
	);
	print qq(
	<div id="problem_wrapper">
		<div class="form_title">Problem Details</div>
		<div id="problem_div">
		
		<label for="problem">Problem:</label><div id="problem" name="problem">$results->{'problem'}</div><br>
		<label for="troubleshoot">Troubleshooting Tried:</label><textarea cols="80" rows="8" id="troubleshooting" name="troubleshooting" class="styled_form_element"></textarea><br>
		<label for="past_troubleshoot">Past Troubleshooting:</label><div id="past_troubleshoot" name="past_troubleshoot">
	);
	
	my @hash_order = keys %$troubleshooting;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print " - " . substr($troubleshooting->{$t}->{'performed'},0,16) . "<br />";
		print $troubleshooting->{$t}->{'troubleshooting'} . "<br />";
	}
	
	print qq(</div><br />
		<label for="notes">Notes:</label><textarea rows="8" cols="80" id="notes" name="notes" class="styled_form_element"></textarea><br/>
	);

	print qq(<label for="past_notes">Past Notes:</label><div id="past_notes" name="past_notes">);
	@hash_order = keys %$notes;
	
	@hash_order = sort {$b <=> $a} @hash_order;
	
	foreach my $t (@hash_order)
	{
		print "------------------------------------------------------<br />";
		print " - " . substr($notes->{$t}->{'performed'},0,16) . "<br />";
		print $notes->{$t}->{'note'} . "<br />";
	}
	print qq(</div><br />
			<input type="image" src="images/update.png" id="update_button" alt="Update">
			<img src="images/cancel.png" alt="Cancel" class="image_button" id="cancel">
		</div>
		<div id="attached_div">
			<div id="attached">
				<label>Attached Files</label>
	);
	my $dir = $config->{'upload_file_dir'} . "/" . $results->{'ticket'};
	opendir(DIR, $dir);
	LINE: while(my $FILE = readdir(DIR)){
		next LINE if($FILE =~ /^\.\.?/);
		unless(-d "$FILE"){
			print qq(<li class="attached_file"><a href="$dir/$FILE">$FILE</a></li>);
		}
	}
	closedir(DIR);
	print qq(
			</div>
			<div id="attach_div"><div id="attach" rel="#multiAttach"><label>Attach a File</label><img src="images/attach.png" title="Attach A File"></div></div>
		</div>
		</form>
	);
	
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
