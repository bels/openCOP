#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use lib './libs';
use ReadConfig;
use SessionFunctions;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my @styles = (
		"styles/ui.jqgrid.css",
		"styles/current_critical.css",
		"styles/ticket_details.css",
	);
	my @javascripts = (
		"javascripts/jquery.tools.min.js",
		"javascripts/jquery.form.js",
		"javascripts/grid.locale-en.js",
		"javascripts/jquery.jqGrid.min.js",
		"javascripts/current_critical.js",
	);

	print "Content-type: text/html\n\n";
	foreach(@styles){
		print qq(
			<link rel="stylesheet" href="$_" type="text/css" media="screen">
		);
	}
	foreach(@javascripts){
		print qq(	
			<script type="text/javascript" src="$_"></script>
		);
	}
	print qq(
		<div id="top">
			<table id="res_table">
			</table>
			<div id="pager">
			</div>
			<div id="ticket_details">
			</div>
			<div id="behind_popup">
			</div>
			<div id="multiAttach" class="dialog">
				<div id="details">
					<form id="attach_form" enctype="multipart/form-data" method="post" action="upload_file.pl">
						<center><label>Attach a file</label></center>
						<input type="hidden" name="mode" id="mode" value="update">
						<input type="file" name="file1" id="file1" num="1">
						<img src="images/plus.png" class="add_file image_button" alt="Add">
						<input type="image" src="images/submit.png" name="close_attach" id="close_attach" class="close" alt="Done">
					</form>
				</div>
			</div>
	);
} else{
	print $q->redirect(-URL => $config->{'index_page'});
}
