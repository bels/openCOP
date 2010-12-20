#!/usr/bin/env perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use Date::Calc;
use POSIX;
use Data::Dumper;


my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $vars = $q->Vars;
	if($vars->{'mode'} eq "by_tech"){
		my $data = $q->Vars;
		my ($page, $total_pages, $count);

		$page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

		my $id = $vars->{'id'};
		my $sd;
		my $ed;	

		if(defined($vars->{'sd'}) && $vars->{'sd'} ne ""){
			$sd = $vars->{'sd'} . " 00:00:00";
		} else {
			$sd = (strftime( '%m/%d/%Y', localtime) . " 00:00:00");
		}
	
		if(defined($vars->{'ed'}) && $vars->{'ed'} ne ""){
			$ed = $vars->{'ed'} . " 23:59:59";
		} else {
			$ed = (strftime( '%m/%d/%Y', localtime) . " 23:59:59");
		}
	
		my $ticket = {};
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $query = "select distinct(ticket) from audit where (technician = ? or updater = ? ) and updated between ? and ?;";
		my $sth = $dbh->prepare($query);
		$sth->execute($id,$id,$sd,$ed);
		my $results = $sth->fetchall_hashref('ticket');
	
		$query = "
			select
				record,
				ticket,
				time_worked,
				updated,
				contact,
				priority,
				technician,
				section,
				status,
				problem
			from
				audit_tickets_by_tech(
					cast(? as integer),
					cast(? as integer),
					cast(? as timestamp),
					cast(? as timestamp)
			)
		";
		my $sth = $dbh->prepare($query);
		foreach(keys %$results){
			$sth->execute($id,$_,$sd,$ed) or die "$query";
			$ticket->{$_} = $sth->fetchall_hashref('record');
		}

		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$ticket;
		} else {
			@ordered = sort { $b <=> $a } keys %$ticket;
		}

		my @innerXML;
		my $count = 0;

		my $new_ticket = {};

		foreach my $t(@ordered){
			$innerXML[$count] .= "<row id='" . $t . "'>";
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				$new_ticket->{$t} = {
					'priority'	=>	$ticket->{$t}->{$r}->{'priority'},
					'problem'	=>	$ticket->{$t}->{$r}->{'problem'},
					'status'	=>	$ticket->{$t}->{$r}->{'status'},
					'contact'	=>	$ticket->{$t}->{$r}->{'contact'},
					'updated'	=>	$ticket->{$t}->{$r}->{'updated'},
					'section'	=>	$ticket->{$t}->{$r}->{'section'},
				};
			}
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				if(defined($new_ticket->{$t}->{'time_worked'}) && $new_ticket->{$t}->{'time_worked'} ne ""){
					if(defined($ticket->{$t}->{$r}->{'time_worked'}) && $ticket->{$t}->{$r}->{'time_worked'} ne ""){
						my @t = split(':',$new_ticket->{$t}->{'time_worked'});
						my @t2 = split(':',$ticket->{$t}->{$r}->{'time_worked'});
						my @t3;
						push(@t3,$t[0] + $t2[0]);
						push(@t3,$t[1] + $t2[1]);
						push(@t3,$t[2] + $t2[2]);
						$new_ticket->{$t}->{'time_worked'} = join(':',@t3);
					}
				} else {
					if(defined($ticket->{$t}->{$r}->{'time_worked'}) && $ticket->{$t}->{$r}->{'time_worked'} ne ""){
						$new_ticket->{$t}->{'time_worked'} = $ticket->{$t}->{$r}->{'time_worked'};
					}
				}
			}
			$innerXML[$count] .= "<cell>" . $t . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'status'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'updated'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'time_worked'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'priority'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'contact'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'problem'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'section'} . "</cell>";
			$innerXML[$count] .= "</row>";
			$count++;
		}
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
		$limit = $start + $limit;

		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		for(my $i = $start; $i < $limit; $i++){
			$xml .= $innerXML[$i];
		}
		$xml .= "</rows>";
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;
	
	} elsif($vars->{'mode'} eq "by_ticket"){
		my $search = $vars->{'search'};
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $data = $q->Vars;
		my ($query, $sth, $page, $total_pages, $count);

		$page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

		$query = "
			select
				record,
				ticket,
				time_worked,
				updated,
				contact,
				priority,
				technician,
				section,
				status,
				problem
			from
				audit_tickets_by_ticket(?)
		";
		$sth = $dbh->prepare($query) or die "Cannot prepare query";
		$sth->execute($search) or die "$query";
		my $ticket->{$search} = $sth->fetchall_hashref('record');

		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$ticket;
		} else {
			@ordered = sort { $b <=> $a } keys %$ticket;
		}
		my @innerXML;
		my $count = 0;

		my $new_ticket = {};
		foreach my $t(@ordered){
			$innerXML[$count] .= "<row id='" . $t . "'>";
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				$new_ticket->{$t} = {
					'priority'	=>	$ticket->{$t}->{$r}->{'priority'},
					'problem'	=>	$ticket->{$t}->{$r}->{'problem'},
					'technician'	=>	$ticket->{$t}->{$r}->{'technician'},
					'status'	=>	$ticket->{$t}->{$r}->{'status'},
					'contact'	=>	$ticket->{$t}->{$r}->{'contact'},
					'updated'	=>	$ticket->{$t}->{$r}->{'updated'},
					'section'	=>	$ticket->{$t}->{$r}->{'section'},
				};
			}
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				if(defined($new_ticket->{$t}->{'time_worked'}) && $new_ticket->{$t}->{'time_worked'} ne "" && $new_ticket->{$t}->{'time_worked'} ne "undef"){
					if(defined($ticket->{$t}->{$r}->{'time_worked'}) && $ticket->{$t}->{$r}->{'time_worked'} ne ""){
						my @t = split(':',$new_ticket->{$t}->{'time_worked'});
						my @t2 = split(':',$ticket->{$t}->{$r}->{'time_worked'});
						my @t3;
						push(@t3,$t[0] + $t2[0]);
						push(@t3,$t[1] + $t2[1]);
						push(@t3,$t[2] + $t2[2]);
						$new_ticket->{$t}->{'time_worked'} = join(':',@t3);
					}
				} else {
					if(defined($ticket->{$t}->{$r}->{'time_worked'}) && $ticket->{$t}->{$r}->{'time_worked'} ne "" && $new_ticket->{$t}->{'time_worked'} ne "undef"){
						$new_ticket->{$t}->{'time_worked'} = $ticket->{$t}->{$r}->{'time_worked'};
					}
				}
			}
	
			$innerXML[$count] .= "<cell>" . $t . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'status'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'updated'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'time_worked'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'priority'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'contact'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'problem'} . "</cell>";
			$innerXML[$count] .= "<cell>" . $new_ticket->{$t}->{'section'} . "</cell>";
			$innerXML[$count] .= "</row>";
			$count++;
		}
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
		$limit = $start + $limit;

		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		for(my $i = $start; $i < $limit; $i++){
			$xml .= $innerXML[$i];
		}
		$xml .= "</rows>";
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
