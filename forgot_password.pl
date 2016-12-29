#!/usr/local/bin/perl

use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;
use SessionFunctions;
use UserFunctions;

#get the referrer so we know if we should display a internal page or a customer page.
my $q = CGI->new;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

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

	$query = "select * from section where name = 'Helpdesk' and not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $section_list = $sth->fetchall_hashref('id');

	my $file = "forgot_password.tt";
	my $meta_keywords = "";
	my $meta_description = "";
	my @styles = ("styles/customer.css");
	my @javascripts = (
		"javascripts/jquery.blockui.js",
		"javascripts/jquery-ui-timepicker-addon.min.js",
		"javascripts/jquery.validate.js",
		"javascripts/main.js",
		"javascripts/forgot_password.js"
	);

	my $title = $config->{'company_name'} . " - Forgot Password";
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
		display_author => $config->{'display_author'},
		display_barcode => $config->{'display_barcode'},
		display_serial => $config->{'display_serial'},
		display_location => $config->{'display_location'},
		display_free_date => $config->{'display_free_date'},
		display_free_time => $config->{'display_free_time'},
	};

		
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
