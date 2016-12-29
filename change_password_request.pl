#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;
use CustomerFunctions;
use ReadConfig;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $q = CGI->new();
my $ticket = Ticket->new(mode => "");
	my $data = $q->Vars;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	my $results;
	my $status = 1;
	my $site;
	foreach my $element (keys %$data){
		if(defined($data->{$element})){
			$data->{$element} =~ s/\'/\'\'/g;
		}
	}
	
	if(defined($data->{'site'}) && $data->{'site'} > 0){
		$site = $data->{'site'};
	} else {
		$site = "1";
	}

	if(defined($data->{'section'})){
	} else {
		$data->{'section'} = "0";
	}

	if(defined($data->{'priority'})){
	} else {
		$data->{'priority'} = "2";
	}

	if($data->{'free_date'}){
	} else {
		$data->{'free_date'} = "now";
	}

	if($data->{'start_time'}){
	} else {
		$data->{'start_time'} = "now";
	}

	if($data->{'end_time'}){
	} else {
		$data->{'end_time'} = "now";
	}

	if($data->{'tech'}){
	} else {
		$data->{'tech'} = "1";
	}
	$data->{'barcode'} = "";
	$data->{'serial'} = "";

	$data->{'submitter'} = '1';
	$data->{'notes'} = "";

		my $query = "
			select
				insert_ticket(
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?,
					?
				);
		";
		my $sth = $dbh->prepare($query);
		$sth->execute(
			$site,
			$status,
			$data->{'barcode'},
			$data->{'location'},
			$data->{'author'},
			$data->{'contact'},
			$data->{'phone'},
			$data->{'troubleshoot'},
			$data->{'section'},
			$data->{'problem'},
			$data->{'priority'},
			$data->{'serial'},
			$data->{'email'},
			$data->{'tech'},
			$data->{'notes'},
			$data->{'submitter'},
			$data->{'free_date'},
			$data->{'start_time'},
			$data->{'end_time'}
		);
		my $id = $sth->fetchrow_hashref;
		my $notify = Notification->new(ticket_number => $id->{'insert_ticket'});

		my $create_ticket = $notify->by_email(mode => 'ticket_create', to => $data->{'email'});
		my $notify_tech;
		if(defined($data->{'tech_email'})){
			$notify_tech = $notify->by_email(mode => 'notify_tech', to => $data->{'tech_email'});
		}
		if($create_ticket->{'error'}){
			$results = {
				'error'		=>	"2",
				'id'		=>	$id->{'insert_ticket'},
				smtp		=>	$create_ticket,
			};
		} elsif($notify_tech->{'error'}){
			$results = {
				'error'		=>	"2",
				'id'		=>	$id->{'insert_ticket'},
				smtp		=>	$notify_tech,
			};
		} else {
			$results = {
				'error'		=>	"0",
				'id'		=>	$id->{'insert_ticket'},
			};
		}
	print "Content-type: text/html\n\n";
	if($results->{'error'} == 1){
		warn "Access denied to section " .  $data->{'section'} . " for user " . $data->{'submitter'};
		print "1";
		print "Access denied";
	} elsif($results->{'error'} == 2){
		warn "Failed to send email.";
		warn $results->{'smtp'}->{'smtp_msg'};
		print "2";
		print "\n" . $results->{'smtp'}->{'smtp_msg'};
	} else {
		print "0";
	}
