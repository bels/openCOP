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
	my $search_params;
	my @possible = ("ticket","status","priority","contact","problem","location","section");

	my $search = 0;
	if(defined($data->{'_search'}) && $data->{'_search'} eq "true"){
		$search = 1;
		foreach(@possible){
			if(defined($data->{$_})){
				$search_params->{$_} = $data->{$_};
			}
		}
	}

	unless($data->{'section'} eq "pseudo"){
		if($search){
			$query = "SELECT get_access(?,?) AS access";
			$sth = $dbh->prepare($query);
			$sth->execute($data->{'section'},$id);
			my $access = $sth->fetchrow_hashref;
			if($access->{'access'}){
				if($access->{'access'} == 1){ # complete access
					$query = "SELECT count(*) from friendly_helpdesk as f WHERE active AND status_id NOT IN ('7')";
					foreach(keys %{$search_params}){
						$query  .= " AND $_ ";
						if($_ eq 'ticket'){
							$query .= "= '$search_params->{$_}'";
						} else {
							$query .= "ilike '$search_params->{$_}%'";
						}
					}
				} elsif($access->{'access'} == 2){ # read access
					$query = "SELECT count(*) from friendly_helpdesk as f WHERE active AND status_id NOT IN ('6','7')";
					foreach(keys %{$search_params}){
						$query  .= " AND $_ ";
						if($_ eq 'ticket'){
							$query .= "= '$search_params->{$_}'";
						} else {
							$query .= "ilike '$search_params->{$_}%'";
						}
					}
				} else { # no access
					$query = "SELECT 0 AS count";
				}
				$sth = $dbh->prepare($query);
				$sth->execute;
			}
		} else {
			$query = "select * from count_tickets(?,?) AS count";
			$sth = $dbh->prepare($query);
			$sth->execute($data->{'section'},$id);
		}
		$count = $sth->fetchrow_hashref;
		$count = $count->{'count'};
	} else {
		$query = "select count(*) from friendly_helpdesk as f where technician_id = $id and active and status_id not in ('6','7')";
		if($search){
			foreach(keys %{$search_params}){
				unless($search_params->{$_} eq 'pseudo'){
					$query  .= " AND $_ ";
					if($_ eq 'ticket'){
						$query .= "= '$search_params->{$_}'";
					} else {
						$query .= "ilike '$search_params->{$_}%'";
					}
				}
			}
		}
		$sth = $dbh->prepare($query);
		$sth->execute;
		$count = $sth->fetchrow_hashref;
		$count = $count->{'count'};
	}

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
		$query = "select ticket,priority,priority_id,name,section_id,status,status_id,problem,contact,location from lookup_ticket($data->{'section'},$id) WHERE 1 = 1";
		if($search){
			foreach(keys %{$search_params}){
				unless($_ eq 'section'){
					$query  .= " AND $_ ";
					if($_ eq 'ticket'){
						$query .= "= '$search_params->{$_}'";
					} else {
						$query .= "ilike '$search_params->{$_}%'";
					}
				}
			}
		}
		$query .= " order by $sidx $sord offset $start limit $limit";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$section->{$data->{'section'}}->{'data'} = $sth->fetchall_arrayref({});
	} else {
		#Currently 6 is the ticket status Closed.  If more ticket statuses are added check to make sure 6 is still closed.  If you start seeing closed ticket in the view then the status number changed
		$query = "
			select
				f.ticket as ticket,
				f.priority as priority,
				f.priority_id as priority_id,
				f.section as name,
				f.section_id as section_id,
				f.status as status,
				f.status_id as status_id,
				f.problem as problem,
				f.location as location,
				f.contact as contact
			from
				friendly_helpdesk as f
			where
				f.status_id not in ('6','7')
			and
				f.technician_id = $id
			and
				f.active
		";
		if($search){
			foreach(keys %{$search_params}){
				unless($_ eq 'pseudo' || $search_params->{$_} eq 'pseudo'){
					$query  .= " AND $_ ";
					if($_ eq 'ticket'){
						$query .= "= '$search_params->{$_}'";
					} else {
						$query .= "ilike '$search_params->{$_}%'";
					}
				}
			}
		}
		$query .= "
			order by $sidx $sord
			offset $start limit $limit;
		";
		$sth = $dbh->prepare($query);
		$sth->execute;
		$section->{$data->{'section'}}->{'data'} = $sth->fetchall_arrayref({});
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
		foreach my $row (@{$section->{$data->{'section'}}->{'data'}}){
			$xml .= "<row id='" . $row->{'ticket'} . "'>";
			$xml .= "<cell>" . $row->{'ticket'} . "</cell>";
			$xml .= "<cell>" . $row->{'status'} . "</cell>";
			$xml .= "<cell>" . $row->{'priority'} . "</cell>";
			$xml .= "<cell>" . $row->{'contact'} . "</cell>";
			$xml .= "<cell>" . $row->{'problem'} . "</cell>";
			$xml .= "<cell>" . $row->{'location'} . "</cell>";
			$xml .= "<cell>" . $row->{'name'} . "</cell>";
			$xml .= "</row>";
		}
		
		$xml .= "</rows>";
		$xml =~ s/\'\'/\'/g;
		print $xml;
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}


