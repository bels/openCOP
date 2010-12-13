#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use SessionFunctions;
use UserFunctions;
use CustomerFunctions;
use FileFunctions;
use ReadConfig;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated){
	$CGI::POST_MAX = $config->{'max_size'} * 1024;
	my $vars = $q->Vars;
#	warn $q->param('attach_input');
#	warn $q->param('file1');

	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "select last_value from helpdesk_ticket_seq;";
	my $sth = $dbh->prepare($query);



	foreach(keys %$vars){
		$sth->execute;
		my $ticket = $sth->fetchrow_hashref;
		warn $config->{'upload_file_dir'};
		warn $ticket->{'last_value'};
		my $upload = FileFunctions->upload_attachment(attachment => $q->upload($_), filename => $q->param($_), max_size => $config->{'maximun_upload_file_size'}, upload_dir => $config->{'upload_file_dir'}, ticket => $ticket->{'last_value'});
		if($upload->{'success'}){
			print "Content-type: text/html\n\n";
		} else {
			print "Content-type: text/html\n\n";
			foreach(keys %$upload){
				warn $upload->{$_};
			}
		}
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
