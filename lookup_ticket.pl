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

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my ($page, $total_pages, $count);
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

	$query = "select id,name from section;";
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
	$query = "select count(*) from helpdesk where section = $data->{'section'};";
	} else {
		$query = "select count(*) from helpdesk where technician = $id;";
	}
	$sth = $dbh->prepare($query);
	$sth->execute;
	$count = $sth->fetchrow_hashref;
	$count = $count->{'count'};
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

	unless($data->{'section'} eq "pseudo"){
		$section->{$data->{'section'}} = $ticket->lookup(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data,section => $data->{'section'}, id => $id, customer => "0", criteria => uri_unescape($data->{'search'}), offset => $start, limit => $limit, order_by => $sidx, order => $sord) or die "What?"; #need to pass in hashref named data
	} else {
		#Currently 6 is the ticket status Closed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$query = "
			select
				helpdesk.ticket as ticket,
				section.name as name,
				status.status as status,
				priority.description as priority,
				helpdesk.problem as problem,
				helpdesk.contact as contact
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
			order by ? $sord
			offset ? limit ?;
		";
		$sth = $dbh->prepare($query);
		push(@placeholders,$sidx);
		push(@placeholders,$start);
		push(@placeholders,$limit);
		$sth->execute(@placeholders);
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
		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %{$section->{$data->{'section'}}};
		} else {
			@ordered = sort { $b <=> $a } keys %{$section->{$data->{'section'}}};
		}
	#	foreach my $row (sort { $a <=> $b } keys %{$section->{$data->{'section'}}})
		foreach my $row (@ordered)
		{
			$xml .= "<row id='" . $section->{$data->{'section'}}->{$row}->{'ticket'} . "'>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'ticket'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'status'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'priority'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'contact'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'problem'} . "</cell>";
			$xml .= "<cell>" . $section->{$data->{'section'}}->{$row}->{'name'} . "</cell>";
			$xml .= "</row>";
		}
		
		$xml .= "</rows>";
		print $xml;
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
