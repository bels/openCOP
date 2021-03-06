#!/usr/local/bin/perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use CustomerFunctions;

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

if($authenticated == 2)
{
	my $data = $q->Vars;
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $data = $q->Vars;
	
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $query;
	my $closed; #used to toggle something in the template file
	if($data->{'status'} eq "open")
	{
		$query = "select * from helpdesk where submitter = '$id' and status <> 6 and status <> 7 and active";
		$closed = 0;
	}
	if($data->{'status'} eq "closed")
	{
		$query = "select * from helpdesk where submitter = '$id' and status = 6;";
		$closed = 1;
	}
	
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $results = $sth->fetchall_arrayref;
	
	my @styles = ( "styles/customer.css","styles/jquery.jscrollpane.css","styles/smoothness/jquery-ui-1.8.5.custom.css");
	my @javascripts = (
		"javascripts/jquery.tools.min.js",
		"javascripts/jquery.form.js",
		"javascripts/jquery.validate.js",
		"javascripts/jquery.jscrollpane.min.js",
		"javascripts/jquery-ui-timepicker-addon.min.js",
		"javascripts/customer.js",
	);
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
