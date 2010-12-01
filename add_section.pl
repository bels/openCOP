#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use SessionFunctions;
use URI::Escape;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $section_name = uri_unescape($q->param('section_name'));
	my $section_email = uri_unescape($q->param('section_email'));
	
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query = "insert into section (name,email) values (?,?)";
	my $sth = $dbh->prepare($query);
	$sth->execute($section_name,$section_email);
	
	print $q->redirect(-URL=> "global_settings.pl?success=1");
} elsif($authenticated == 2){
	print $q->redirect(-URL => $config->{'index_page'})
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
