#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'}, db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'},db_type => $config->{'db_type'});
}

if($authenticated == 1)
{
	
	my $mode = $q->param('mode');

	my $ticket = Ticket->new(mode => $mode);
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

	$ticket->render(id => $id, is_admin => $user->is_admin(id => $id));

}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
