#!/usr/bin/env perl

use lib './libs';
use strict;
use CGI;
use URI::Escape;
use SessionFunctions;
use ReadConfig;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'}, db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');
$session->logout(id=>$cookie{'id'}, auth_table => $config->{'auth_table'});
my $cookie = $q->cookie(-name=>'session',-value=>'',-expires=>'-1h');
print $q->redirect(-cookie=>$cookie,-URL => "customer.pl");
