#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;
use CustomerFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

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

if($authenticated == 1)
{
	my $user;
	my $alias;
	my $id;
	my $data = $q->Vars;
	my $type = $q->url_param('type');

	$alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	if($type eq "customer")
	{
		$user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$data->{'submitter'} = $user->get_user_id(alias => $alias);
		$data->{'notes'} = $q->param('problem');
		$data->{'tech'} = "1";
		$data->{'customer'} = 1;
	}
	else
	{
		$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$data->{'submitter'} = $user->get_user_id(alias => $alias);
		$data->{'notes'} = "";
		$data->{'customer'} = 0;
	}

	if(defined($data->{'tech'})){
		$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		$id = $user->get_user_info(alias => $data->{'tech'});
		$data->{'tech_email'} = $id->{'email'};
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
