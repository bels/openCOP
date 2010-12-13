#!/usr/bin/env perl

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

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated){
	my $data = $q->Vars;

	$data->{'submitter'} = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	$data->{'notes'} = "";

	if(defined($data->{'tech'}) && $data->{'tech'}){
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		my $info = $user->get_user_info(user_id => $data->{'tech'});
		$data->{'tech_email'} = $info->{'email'};
	}
	my $access = $ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data); #need to pass in hashref named data
	print "Content-type: text/html\n\n";
	if($access->{'error'}){
		warn "Access denied to section " .  $data->{'section'} . " for user " . $data->{'submitter'};
		print "1";
		print "Access denied";
	} else {
		print "0";
	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
