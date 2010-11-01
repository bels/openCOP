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
	my $data;
	
	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "init"){
		my $type = $vars->{'type'};
		$query = "select property.property,type_property.tpid,type_property.property_id from type_property join property on type_property.property_id = property.pid where type_id = '$type';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $used_properties;

		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_properties  = $sth->fetchall_hashref('pid');
		my @used_properties;

		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="tp_select_array[]">
		);

		if(defined($used_properties->{'tpid'})){
			$used_properties = $sth->fetchall_hashref('tpid');
			foreach my $key (keys %$used_properties){
				push(@used_properties,$used_properties->{$key}->{'property_id'});
				$data .= qq(<option selected="selected" value="$used_properties->{$key}->{'property_id'}">$used_properties->{$key}->{'property'}</option>);
			}
		}
		foreach my $key (keys %$all_properties){
			foreach (@used_properties){
				if($_ =~ m/$all_properties->{$key}->{'pid'}/) {
					delete($all_properties->{$key});
				}
			}
			if($all_properties->{$key}){
				$data .= qq(<option value="$all_properties->{$key}->{'pid'}">$all_properties->{$key}->{'property'}</option>);
			}
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "associate"){
		my $type = $vars->{'type'};
		my $selected_string = $vars->{'selected'};
		my $unselected_string = $vars->{'unselected'};
		my $error;

		for($selected_string,$unselected_string){
			$_ =~ s/:$//;
		}

		my @selected = split(":",$selected_string);
		my @unselected = split(":",$unselected_string);

		for my $i (@unselected) {
			$query = "delete from type_property where type_id = '$type' and property_id = '$i';";
			$sth = $dbh->prepare($query);
			$sth->execute;
		}

		for my $i (@selected) {
			$query = "delete from type_property where type_id = '$type' and property_id = '$i';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			$query = "select count(*) from type_property where type_id = '$type' and property_id = '$i';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $count = $sth->fetchrow_hashref;
			unless($count->{'count'}){
				$query = "insert into type_property(type_id,property_id) values('$type','$i');";
				$sth = $dbh->prepare($query);
				$sth->execute;
			} else {
				$error++;
			}
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
		}
	} elsif ($vars->{'mode'} eq "onload"){
		$query = "select * from type;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('tid');
		$data = qq(
				<select id="type_select" class="type_select">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$results){
			$data .= qq(<option value="$results->{$key}->{'tid'}">$results->{$key}->{'type'}</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "object_onload"){
		$query = "select * from type;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('tid');
		$data = qq(
				<select id="object_type_select">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$results){
			$data .= qq(<option value="$results->{$key}->{'tid'}">$results->{$key}->{'type'}</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "onload_more"){
		$query = "select * from type;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('tid');
		$data = qq(
				<select id="del_tp" class="type_select">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$results){
			$data .= qq(<option value="$results->{$key}->{'tid'}">$results->{$key}->{'type'}</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "load_properties"){
		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('pid');
		$data = qq(
				<select id="del_tp">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$results){
			$data .= qq(<option value="$results->{$key}->{'pid'}">$results->{$key}->{'property'}</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "populate_create_form"){
		my $type = $vars->{'type'};
		$query = "select property.property,type_property.tpid,type_property.property_id from type_property join property on type_property.property_id = property.pid where type_id = '$type';";
		warn $query;
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('tpid');
		$data .= "\n";
		foreach my $key (keys %$results){
			$data .= qq(
				<div id="$results->{$key}->{'tpid'}" class="object_form_div"><label class="object_form_label">$results->{$key}->{'property'}</label><input id="$results->{$key}->{'property_id'}" class="object_form_input"></div>
			);
		}
		print "Content-type: text/html\n\n";
		print $data;
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this!";
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
