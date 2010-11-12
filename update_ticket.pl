#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;
my $alias;
my $id;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

	$alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	$id = $user->get_user_info(alias => $alias);

	my $data = $q->Vars;
	$data->{'updater'} = $id->{'id'};

	my $access = $ticket->update(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data); #need to pass in hashref named data
	if($access->{'error'}){
		warn "Access denied to section " .  $data->{'section'} . " for user " . $data->{'submitter'};
	}
	print $q->redirect(-URL=>"ticket.pl?mode=lookup");
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
