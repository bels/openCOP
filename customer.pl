#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use warnings;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 2){
	my @styles = (
		"styles/smoothness/jquery-ui-1.8.5.custom.css",
		"styles/customer.css"
	);
	my @javascripts = (
		"javascripts/jquery.tools.min.js",
		"javascripts/jquery.validate.js",
		"javascripts/jquery.blockui.js",
		"javascripts/jquery-ui-timepicker-addon.min.js",
		"javascripts/jquery.form.js",
		"javascripts/main.js",
		"javascripts/ticket.js",
	);
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

	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
	my $info = $user->get_user_info(user_id => $id);

	my $submitter = $info->{'first'} . " " . $info->{'last'};
	my $email = $info->{'email'};
	my $site = $info->{'site'};

	my $file = "customer.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'keywords' => $meta_keywords,
		'description' => $meta_description,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		site_list => $site_list,
		priority_list => $priority_list,
		section_list => $section_list,
		author => $submitter,
		customer_email => $email,
		display_author => $config->{'display_author'},
		display_barcode => $config->{'display_barcode'},
		display_serial => $config->{'display_serial'},
		display_location => $config->{'display_location'},
		display_free_date => $config->{'display_free_date'},
		display_free_time => $config->{'display_free_time'},
		site => $site,
		backend => $config->{'backend'},
	};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} elsif($authenticated == 1){
	print $q->redirect(-URL => "main.pl");
} else {
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
