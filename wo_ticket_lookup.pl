#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use Template;
use SessionFunctions;
use POSIX 'ceil';

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $data = $q->Vars;
	my $wo_number = $data->{'wo'};
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";

	my $page = $data->{'page'};
	if(!$page){$page=1};
	my $limit = $data->{'rows'};
	if(!$limit){$limit=10};
	my $sidx = $data->{'sidx'};
	if(!$sidx){$sidx = 1};
	my $sord = $data->{'sord'};

	my $query = "select count(*) from wo_ticket where wo_id = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($wo_number);
	my $count = $sth->fetchrow_hashref;
	$count = $count->{'count'};
	my $total_pages;
	if( $count > 0 && $limit > 0) {
		$total_pages = ceil($count/$limit); 
	} else { 
		$total_pages = 0;
	} 
	if($page > $total_pages){
		$page=$total_pages;
	}
	my $start = $limit * $page - $limit;
	if($start<0){$start=0};

	my $query = "select * from wo_ticket where wo_id = ? order by ? $sord offset ? limit ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($wo_number,$sidx,$start,$limit);
	my $wo = $sth->fetchall_arrayref({});

	$query = "
			select
				helpdesk.ticket as ticket,
				helpdesk.active as active,
				section.name as name,
				users.alias as technician,
				status.status as status,
				priority.description as priority,
				helpdesk.problem as problem
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
				helpdesk.ticket = ?
	";
	$sth = $dbh->prepare($query);

		print "Content-type: text/xml;charset=utf-8\n\n";

		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		foreach my $row (@{$wo}){
			$sth->execute($row->{'ticket_id'});
			my $ticket = $sth->fetchrow_hashref;
			$xml .= "<row id='" . $row->{'ticket_id'}.  "'>";
			$xml .= "<cell>" . $row->{'step'}	. "</cell>";
			$xml .= "<cell>" . $row->{'ticket_id'}	. "</cell>";
			$xml .= "<cell>" . $ticket->{'status'}		. "</cell>";
			$xml .= "<cell>" . $ticket->{'priority'}	. "</cell>";
			$xml .= "<cell>" . $ticket->{'technician'}	. "</cell>";
			$xml .= "<cell>" . $ticket->{'problem'}		. "</cell>";
			$xml .= "<cell>" . $ticket->{'name'}		. "</cell>";
			$xml .= "</row>";
		}
		
		$xml .= "</rows>";
		$xml =~ s/\'\'/\'/g;
		print $xml;
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
