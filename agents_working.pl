#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use UserFunctions;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select * from agents_working()";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $result = $sth->fetchall_hashref('id');
	print "Content-type: text/html\n\n";
	print qq(
		<link rel="stylesheet" href="styles/agents_working.css" type="text/css" media="screen">
		<script type="text/javascript" src="javascripts/jquery.tablesorter.js"></script>
		<script type="text/javascript" src="javascripts/agents_working.js"></script>

		<table id="agents_working_table">
			<thead>
				<tr class="header_row">
					<th class="header_cell">These technicians are online</th>
					<th class="header_cell">They have been online for</th>
				</tr>
			</thead>
			<tbody>
	);
	foreach(sort { $a <=> $b } keys %$result){
		print qq(
				<tr class="agent_row">
					<td class="agent_cell">$result->{$_}->{'alias'}</td>
					<td class="agent_cell">) . substr($result->{$_}->{'logged_in'},0,-7) . qq(</td>
				</tr>
		);
	}
	print qq(
			</tbody>
		</table>
	);
}
else{
	print $q->redirect(-URL => $config->{'index_page'});
}
