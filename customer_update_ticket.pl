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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $vars = $q->Vars;
	my $tkid = $vars->{'tkid'};
	my $new_note = $vars->{'new_note'};

	foreach ($new_note){
		$_  =~ s/\'/\'\'/g;
	}

	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $id = $user->get_user_info(alias => $alias);

	my $updater = $id->{'id'};

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query = "insert into notes (ticket_id, note) values(?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($tkid,$new_note);
	my $query = "update helpdesk set free_date = ?, free_time = ? where ticket = ?";
	my $sth = $dbh->prepare($query);
	$sth->execute($vars->{'free_date'},$vars->{'free_time'},$tkid);
	$query = "insert into audit (notes,updater,ticket) values(?,?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($new_note,$updater,$tkid);
	
	print "Content-type: text/html\n\n";
}	
else
{
	print $q->redirect(-URL => $config->{'customer.pl'});
}
