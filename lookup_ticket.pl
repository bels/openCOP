#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;
use URI::Escape;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my @placeholders = ($id);
	#This part will build the where clause to search all columns of the same datatype as the data passed in from the search box
	my $query;
	my $sth;
	my $where = " AND ("; #this gets tacked on the end if search is defined.
	if(defined($data->{'search'})){
		if($data->{'search'} =~ m/\D/){
			my @columns = ('troubleshooting.troubleshooting','users.alias','helpdesk.location','helpdesk.author','helpdesk.contact','helpdesk.notes','section.name','helpdesk.problem','priority.description','helpdesk.serial','helpdesk.contact_email','status.status','site.name');
			foreach my $key (@columns){
				$where .= "$key ILIKE ? OR ";
				push(@placeholders,"%".uri_unescape($data->{'search'})."%");
			}
		} else {
			my @columns = ('helpdesk.ticket');
			foreach my $key (@columns){
				$where .= "$key = ? OR ";
				push(@placeholders,uri_unescape($data->{'search'}));
			}
		}
		chomp($where);
		chop($where); #removing the extra OR at the end
		chop($where);
		chop($where);
		$where .= ")";
	}
	
	my $section = {};

	print "Content-type: text/html\n\n";

	$query = "select id,name from section;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');
	
	unless($data->{'section'} eq "pseudo"){
		$section->{$data->{'section'}} = $ticket->lookup(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data,section => $data->{'section'}, id => $id, customer => "0", criteria => uri_unescape($data->{'search'})) or die "What?"; #need to pass in hashref named data
	} else {
		#Currently 6 is the ticket status Closed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$query = "
			select
				helpdesk.ticket as ticket,section.name as name,status.status as status, priority.description as priority, helpdesk.contact as contact
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
			where
				helpdesk.status not in ('6','7')
			and
				helpdesk.active
			and
				helpdesk.technician = ?
			";
		if(defined($data->{'search'})){
			$query .= $where;
		}
		$query .= "
					order by ticket;
		";
		$sth = $dbh->prepare($query);
		$sth->execute(@placeholders);
		$section->{$data->{'section'}} = $sth->fetchall_hashref('ticket');
	}
	if($section->{$data->{'section'}}->{'error'}) {
		warn "Access denied to section " .  $data->{'section'} . " for user $id";
	} else {
		my @hash_order = (keys %{$section->{$data->{'section'}}});
		
		@hash_order = sort({$a <=> $b } @hash_order);
	
		print qq(
			<table class="ticket_summary sort">
				<thead>
					<tr class="header_row">
						<th class="ticket_number header_row_item">Ticket Number</th>
						<th class="ticket_status header_row_item">Ticket Status</th>
						<th class="ticket_priority header_row_item">Ticket Priority</th>
						<th class="ticket_contact header_row_item">Ticket Contact</th>
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
						<td class="row_ticket_section">$section->{$data->{'section'}}->{$element}->{'name'}</td>
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
