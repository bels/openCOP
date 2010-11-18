#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},sid => $cookie{'sid'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $query;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $title;
	my $types;
	my $properties;
	my $file;

	my @styles = ("styles/layout.css","styles/inventory.css","styles/ui.multiselect.css","styles/smoothness/jquery-ui-1.8.5.custom.css");
	my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery-ui-1.8.5.custom.min.js","javascripts/ui.multiselect.js","javascripts/jquery.livequery.js");

	my $mode = $q->param('mode');
	if ($mode eq "add"){
		$title = $config->{'company_name'} . " - Inventory Add";
		$file = "inventory_add.tt";
		push(@styles,"styles/inventory_add.css");
		push(@javascripts,"javascripts/inventory_add.js");
	} elsif ($mode eq "current"){
		$title = $config->{'company_name'} . " - Inventory Current";
		$file = "inventory_current.tt";
		push(@styles,"styles/inventory_current.css","styles/jquery.jscrollpane.css");
		push(@javascripts,"javascripts/inventory_current.js","javascripts/jquery.tablesorter.js","javascripts/jquery.jscrollpane.min.js","javascripts/jquery.livequery.js","javascripts/jquery.mousewheel.js","javascripts/mwheelIntent.js");
	} elsif ($mode eq "configure"){
		$title = $config->{'company_name'} . " - Inventory Configure.";
		$file = "inventory_configure.tt";
		push(@styles,"styles/inventory_configure.css");
		push(@javascripts,"javascripts/inventory_configure.js");
	} else {
		$title = $config->{'company_name'} . " - Inventory Index";
		$file = "inventory_index.tt";
		push(@styles,"styles/inventory_index.css");
		push(@javascripts,"javascripts/inventory_index.js");
	}
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, types => $types};

	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
