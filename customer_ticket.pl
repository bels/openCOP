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
	my $data = $q->Vars;
	my $userid;
	
	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},sid => $cookie{'sid'});
	my $userid = $user->get_user_info(alias => $alias);

	my $data = $q->Vars;
	my $uid = $userid->{'cid'};
	
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in customer_ticket.pl";
	my $query;
	my $closed; #used to toggle something in the template file
	if($data->{'status'} eq "open")
	{
		$query = "select * from helpdesk where submitter = '$uid' and status <> 6 and status <> 7";
		$closed = 0;
	}
	if($data->{'status'} eq "closed")
	{
		$query = "select * from helpdesk where submitter = '$uid' and status = 6 or status = 7";
		$closed = 1;
	}
	
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchall_arrayref;
	
	my @styles = ("styles/layout.css", "styles/customer.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/customer.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $file = "customer_tickets.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, status => $data->{'status'}, id => $data->{'customer_id'}, tickets => $results, closed => $closed};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => "customer.pl");
}
