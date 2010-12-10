#!/usr/bin/env perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use Date::Calc;
use POSIX 'strftime';
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
		my $id = $vars->{'id'};
		my $sd;
		my $ed;	

		if(defined($vars->{'sd'}) && $vars->{'sd'} ne ""){
			$sd = $vars->{'sd'} . " 00:00:00";
			warn $sd;
		} else {
			$sd = (strftime( '%m/%d/%Y', localtime) . " 00:00:00");
			warn $sd;
		}
	
		if(defined($vars->{'ed'}) && $vars->{'ed'} ne ""){
			$ed = $vars->{'ed'} . " 23:59:59";
			warn $ed;
		} else {
			$ed = (strftime( '%m/%d/%Y', localtime) . " 23:59:59");
			warn $ed;
		}
	
		my $ticket = {};
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $query = "select distinct(ticket) from audit where (technician = ? or updater = ? ) and updated between ? and ?;";
		my $sth = $dbh->prepare($query);
		$sth->execute($id,$id,$sd,$ed);
		my $results = $sth->fetchall_hashref('ticket');
	
		$query = "select * from audit_tickets_by_tech(?,?,?,?);";
		my $sth = $dbh->prepare($query);
		foreach(keys %$results){
			$sth->execute($id,$_,$sd,$ed) or die "$query";
			$ticket->{$_} = $sth->fetchall_hashref('record');
		}
		# warn Dumper $ticket;
	
		print "Content-type: text/html\n\n";
		print qq(
			<table id="time_tracking_table" class="sort">
				<thead>
					<tr class="header_row">
						<th class="header_cell">Ticket #</th>
						<th class="header_cell">Current Status</th>
						<th class="header_cell">Last Updated</th>
						<th class="header_cell">Time Worked</th>
						<th class="header_cell">Problem</th>
						<th class="header_cell">Notes</th>
					</tr>
				</thead>
				<tbody>
		);
		my $new_ticket = {};
		foreach my $t (sort { $a <=> $b } keys %$ticket){
			print qq(
				<tr class="body_row">
			);
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				$new_ticket->{$t} = {
					'priority'	=>	$ticket->{$t}->{$r}->{'priority'},
					'problem'	=>	$ticket->{$t}->{$r}->{'problem'},
					'technician'	=>	$ticket->{$t}->{$r}->{'technician'},
					'status'	=>	$ticket->{$t}->{$r}->{'status'},
					'contact'	=>	$ticket->{$t}->{$r}->{'contact'},
					'closed_date'	=>	$ticket->{$t}->{$r}->{'closed_date'},
					'closed_by'	=>	$ticket->{$t}->{$r}->{'closed_by'},
					'completed_by'	=>	$ticket->{$t}->{$r}->{'completed_by'},
					'updated'	=>	$ticket->{$t}->{$r}->{'updated'},
					'location'	=>	$ticket->{$t}->{$r}->{'location'},
					'completed_date'=>	$ticket->{$t}->{$r}->{'completed_data'},
					'updater'	=>	$ticket->{$t}->{$r}->{'updater'},
					'site'		=>	$ticket->{$t}->{$r}->{'site'},
					'contact_email'	=>	$ticket->{$t}->{$r}->{'contact_email'},
				};
			}
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				if(defined($new_ticket->{$t}->{'notes'})){
					if(defined($ticket->{$t}->{$r}->{'notes'}) && $ticket->{$t}->{$r}->{'notes'} ne ""){
						$new_ticket->{$t}->{'notes'} .= ($ticket->{$t}->{$r}->{'notes'} . "\n");
					}
				} else {
					if(defined($ticket->{$t}->{$r}->{'notes'}) && $ticket->{$t}->{$r}->{'notes'} ne ""){
						$new_ticket->{$t}->{'notes'} .= ($ticket->{$t}->{$r}->{'notes'} . "\n");
					}
				}
	
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
	
			print qq(
					<td class="body_cell">$t</td>
					<td class="body_cell">$new_ticket->{$t}->{'status'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'updated'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'time_worked'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'problem'}</td>
					<td class="body_cell" id="notes">) . $new_ticket->{$t}->{'notes'} . qq(</td>
				</tr>
			);
		}
	} elsif($vars->{'mode'} eq "by_ticket"){
		my $search = $vars->{'search'};
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

		my $query = "select * from audit_tickets_by_ticket(?);";
		my $sth = $dbh->prepare($query);
		$sth->execute($search) or die "$query";
		my $ticket->{$search} = $sth->fetchall_hashref('record');

		print "Content-type: text/html\n\n";
		print qq(
			<table id="time_tracking_table" class="sort">
				<thead>
					<tr class="header_row">
						<th class="header_cell">Ticket #</th>
						<th class="header_cell">Current Status</th>
						<th class="header_cell">Last Updated</th>
						<th class="header_cell">Time Worked</th>
						<th class="header_cell">Problem</th>
						<th class="header_cell">Notes</th>
					</tr>
				</thead>
				<tbody>
		);

		my $new_ticket = {};
		foreach my $t (sort { $a <=> $b } keys %$ticket){
			print qq(
				<tr class="body_row">
			);
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				$new_ticket->{$t} = {
					'priority'	=>	$ticket->{$t}->{$r}->{'priority'},
					'problem'	=>	$ticket->{$t}->{$r}->{'problem'},
					'technician'	=>	$ticket->{$t}->{$r}->{'technician'},
					'status'	=>	$ticket->{$t}->{$r}->{'status'},
					'contact'	=>	$ticket->{$t}->{$r}->{'contact'},
					'closed_date'	=>	$ticket->{$t}->{$r}->{'closed_date'},
					'closed_by'	=>	$ticket->{$t}->{$r}->{'closed_by'},
					'completed_by'	=>	$ticket->{$t}->{$r}->{'completed_by'},
					'updated'	=>	$ticket->{$t}->{$r}->{'updated'},
					'location'	=>	$ticket->{$t}->{$r}->{'location'},
					'completed_date'=>	$ticket->{$t}->{$r}->{'completed_data'},
					'updater'	=>	$ticket->{$t}->{$r}->{'updater'},
					'site'		=>	$ticket->{$t}->{$r}->{'site'},
					'contact_email'	=>	$ticket->{$t}->{$r}->{'contact_email'},
				};
			}
			foreach my $r (sort { $a <=> $b } keys %{$ticket->{$t}}){
				if(defined($new_ticket->{$t}->{'notes'})){
					if(defined($ticket->{$t}->{$r}->{'notes'}) && $ticket->{$t}->{$r}->{'notes'} ne ""){
						$new_ticket->{$t}->{'notes'} .= ($ticket->{$t}->{$r}->{'notes'} . "\n");
					}
				} else {
					if(defined($ticket->{$t}->{$r}->{'notes'}) && $ticket->{$t}->{$r}->{'notes'} ne ""){
						$new_ticket->{$t}->{'notes'} .= ($ticket->{$t}->{$r}->{'notes'} . "\n");
					}
				}
	
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
	
			print qq(
					<td class="body_cell">$t</td>
					<td class="body_cell">$new_ticket->{$t}->{'status'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'updated'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'time_worked'}</td>
					<td class="body_cell">$new_ticket->{$t}->{'problem'}</td>
					<td class="body_cell" id="notes">) . $new_ticket->{$t}->{'notes'} . qq(</td>
				</tr>
			);
		}
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
