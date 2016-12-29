#!/usr/local/bin/perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use ReportFunctions;
use DBI;
use Data::Dumper;

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

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $report = ReportFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $reports = $report->view(id => $id);

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $vars = $q->Vars;
	my @prepare_array = ($vars->{'id'});
	my $query;
	my $sth;

	$query = "select get_report(?);";
	$sth = $dbh->prepare($query);
	$sth->execute(@prepare_array);
	my $result = $sth->fetchrow_hashref;

	$sth = $dbh->prepare($result->{'get_report'});
	$sth->execute;
	my $results = $sth->fetchall_hashref(1);

	my @sorted_hash = sort {$a <=> $b} (keys %$results);
	$query = "select * from inventory where object in ($result->{'get_report'})";
	my $store = $query;
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $columns = $sth->fetchall_hashref('property');

	$query = "select name from reports where id = ?";
	$sth = $dbh->prepare($query);
	$sth->execute(@prepare_array);
	my $name = $sth->fetchrow_hashref;
	$name = $name->{'name'};
	my @columns;

#	warn Dumper $columns;
	foreach(sort keys %$columns){
		push(@columns,$_);
	}

	print "Content-type: text/html\n\n";
	my @styles = (
		"styles/ui.jqgrid.css",
		"styles/display_report.css"
	);
	my @javascripts = (
		"javascripts/grid.locale-en.js",
		"javascripts/jquery.jqGrid.min.js",
		"javascripts/jquery.download.js",
		"javascripts/jquery.validate.js",
		"javascripts/jquery.blockui.js",
		"javascripts/jquery.json-2.2.js",
		"javascripts/jquery.mousewheel.js",
		"javascripts/mwheelIntent.js",
		"javascripts/main.js",
		"javascripts/display_report.js"
	);
	#warn $store;
	my $title = $config->{'company_name'} . " - $vars->{'name'}";
	my $file = "display_report.tt";
	my $vars = {
		'title' => $title,
		'styles' => \@styles,
		'javascripts' => \@javascripts,
		'company_name' => $config->{'company_name'},
		logo => $config->{'logo_image'},
		results => $results,
		is_admin => $user->is_admin(id => $id),
		reports => $reports,
		columns => \@columns,
		report_name => $name,
		query => $store,
	};

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
