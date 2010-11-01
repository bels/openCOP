#!/usr/bin/env perl

use strict;
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
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'})  or die "Database connection failed in $0";
	my $sth;
	my $data

	my $type = $q->param('type');
	$query = "select property.property,type_property.tpid,type_property.property_id from type_property join property on type_property.property_id = property.pid where type_id = '$type';";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $used_properties = $sth->fetchall_hashref('tpid');
	$query = "select * from property;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $all_properties  = $sth->fetchall_hashref('pid');

	$data .= qq(
	<select id="associate_tp" class="multiselect" multiple="multiple" name="tp_select_array[]">
	);
	foreach my $key (keys %$used_properties){
		$data .= qq(<option selected="selected" type="$used_properties->{$key}->{'property_id'}">$used_properties->{$key}->{'property'}</option>);
	}
	foreach my $key (keys %$all_properties){
		unless($used_properties->{$key}->{'property_id'} == $all_properties->{$key}->{'pid'}) {
			$data .= qq(<option type="$all_properties->{$key}->{'pid'}">$all_properties->{$key}->{'property'}</option>
		}
	}
	$data .= qq(</select>);
	print $data;

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
