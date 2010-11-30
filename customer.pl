#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use warnings;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use CustomerFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my @styles = ( "styles/customer.css","styles/smoothness/jquery-ui-1.8.5.custom.css");
	my @javascripts = ("javascripts/main.js","javascripts/ticket.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery-ui-timepicker-addon.min.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";

	my $query;
	my $sth;
	
	$query = "select * from priority;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $priority_list = $sth->fetchall_hashref('id');

	$query = "select * from site where not deleted;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $site_list = $sth->fetchall_hashref('id');

	$query = "select * from section where name = 'Helpdesk';";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');

	my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $user = CustomerFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $user->get_user_info(alias => $alias);
	my $submitter = $id->{'first'} . " " . $id->{'last'};
	my $email = $id->{'email'};
	my $site = $id->{'site'};

	my $file = "customer.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},site_list => $site_list, priority_list => $priority_list, section_list => $section_list, author => $submitter, customer_email => $email, display_author => $config->{'display_author'}, display_barcode => $config->{'display_barcode'}, display_serial => $config->{'display_serial'}, display_location => $config->{'display_location'}, display_free_date => $config->{'display_free_date'}, display_free_time => $config->{'display_free_time'}, site => $site};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	my $errorcode;
	$errorcode = $q->param('errorcode') or $errorcode = 0;
	my $vars;
	my @styles = ( "styles/customer.css");
	my @javascripts = ("javascripts/jquery.validate.js","javascripts/customer_login.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	
	if ($errorcode == 1){
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, support_email => $config->{'support_email'}, support_phone_number => $config->{'support_phone_number'},'errorcode' => $errorcode};		
	} else {
		$vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, support_email => $config->{'support_email'}, support_phone_number => $config->{'support_phone_number'}};
	}

	my $file = "customer_login.tt";
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
