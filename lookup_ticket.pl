#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;
use URI::Escape;
use POSIX qw(ceil);

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'}, db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my ($page, $total_pages, $count);
	my $data = $q->Vars;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $query;
	my $sth;
	my $section = {};

	$query = "select id,name from section where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');

	$page = $data->{'page'};
	if(!$page){$page=1};
	my $limit = $data->{'rows'};
	if(!$limit){$limit=10};
	my $sidx = $data->{'sidx'};
	if(!$sidx){$sidx = 1};
	my $sord = $data->{'sord'};

	unless($data->{'section'} eq "pseudo"){
		$query = "select * from count_tickets(?,?)";
		$sth = $dbh->prepare($query);
		$sth->execute($data->{'section'},$id);
		$count = $sth->fetchrow_hashref;
		$count = $count->{'count_tickets'};
	} else {
		$query = "select count(*) from helpdesk where technician = $id and active and status not in ('6','7')";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$count = $sth->fetchrow_hashref;
		$count = $count->{'count'};
	}

	if( $count > 0 && $limit > 0) {
		$total_pages = ceil($count/$limit); 
		warn "Total Pages: $total_pages";
	} else { 
		$total_pages = 0;
	} 

	if($page > $total_pages){
		$page=$total_pages;
	}

	my $start = $limit * $page - $limit;
	if($start<0){$start=0};

	unless($data->{'section'} eq "pseudo"){
		$query = "select ticket,pid,name,status,priority,problem,contact,location from lookup_ticket($data->{'section'},$id) order by $sidx $sord offset $start limit $limit";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$section->{$data->{'section'}} = $sth->fetchall_hashref('ticket');
	} else {
		#Currently 6 is the ticket status Closed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$query = "
			select
				helpdesk.ticket as ticket,
				section.name as name,
				status.status as status,
				priority.description as priority,
				helpdesk.problem as problem,
				helpdesk.location as location,
				helpdesk.contact as contact
			from
				helpdesk
				join
					section on section.id = helpdesk.section
				join
					priority on priority.severity = helpdesk.priority
				join
					status on status.id = helpdesk.status
			where
				helpdesk.status not in ('6','7')
			and
				helpdesk.technician = $id
			and
				helpdesk.active
			order by $sidx $sord
			offset $start limit $limit;
		";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$section->{$data->{'section'}} = $sth->fetchall_hashref('ticket');
	}
	if($section->{$data->{'section'}}->{'error'}) {
		warn "Access denied to section " .  $data->{'section'} . " for user $id";
	} else {
		print "Content-type: text/xml;charset=utf-8\n\n";

		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		foreach my $row (sort { $a <=> $b } keys %{$section->{$data->{'section'}}}){
			warn $row;
			$xml .= "<row id='" . $section->{$data->{'section'}}->{$row}->{'ticket'} . "'>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'ticket'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'status'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'priority'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'contact'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'problem'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'location'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'name'} . "</cell>";
			$xml .= "</row>";
		}
		
		$xml .= "</rows>";
		$xml =~ s/\'\'/\'/g;
		print $xml;
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
