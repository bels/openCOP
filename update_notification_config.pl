#!/usr/bin/env perl
use lib './libs';
use strict;
use warnings;
use CGI;
use URI::Escape;
use ReadConfig;
use DBI;
use SessionFunctions;
use UserFunctions;
use YAML;
use JSON;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $vars = $q->Vars;
	my $object = from_json($vars->{'object'});
	my $notification = {};
	foreach(@{$object}){
		$notification->{$_->{'name'}} = $_->{'value'};
	}
	
	YAML::DumpFile("/usr/local/etc/opencop/notification.yml",$notification);
	print "Content-type: text/html\n\n";
}
else{
	print $q->redirect(-URL => $config->{'index_page'});
}
