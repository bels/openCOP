#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $tkid = $q->param('tkid');
	my $new_note = $q->param('new_note');

	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},sid => $cookie{'sid'});
	my $uid = $user->get_user_info(alias => $alias);

	my $updater = $uid->{'cid'};

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query = "insert into notes (tkid, note) values($tkid,'$new_note')";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	$query = "insert into audit (notes,updater,ticket) values('$new_note','$updater','$tkid')";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	
	print "Content-type: text/html\n\n";
}	
else
{
	print $q->redirect(-URL => $config->{'customer.pl'});
}
