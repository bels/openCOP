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

		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $properties = $sth->fetchall_hashref('pid');

		$query = "select * from company where hidden = false;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $companies= $sth->fetchall_hashref('cpid');

		$data = qq(
				<form id="add_object_form">
					<label for="object_type_select" class="add type_select">Create </label>
					<div id="object_type_append_div">
				<select id="object_type_select">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$results){
			$data .= qq(<option value="$results->{$key}->{'tid'}">$results->{$key}->{'type'}</option>);
		}
		$data .= qq(	</select>);

		$data .= qq(	
				<div id="company_select_div" class="select_div">
					<label for="object_company_select" class="add company_select">Company</label>
					<select id="object_company_select" class="company_select">
						<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$companies){
			$data .= qq(<option value="$companies->{$key}->{'cpid'}">$companies->{$key}->{'name'}</option>);
		}
		$data .= qq(	</select>
				</div>
		);

		$data .= qq(
				
				<div id="property_select_div" class="select_div">
				<label for="object_property_select" class="add property_select">Add new property </label>
				<select id="object_property_select" class="property_select">
					<option value="" selected="selected"></option>
		);
		foreach my $key (keys %$properties){
			$data .= qq(<option value="$properties->{$key}->{'pid'}">$properties->{$key}->{'property'}</option>);
		}
		$data .= qq(	</select>
				</div>
		);

		$data .= qq(
					</div>
				</form>
		);

		$data .= qq(
						<button id="submit_create_object_button" class="submit_button left_add_object">Create</button>
						<button id="submit_add_property_button" class="submit_button left_add_object">Add</button>
		);
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
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('tpid');
		foreach my $key (keys %$results){
			$data .= qq(
				<br><label class="object_form_label object_form">$results->{$key}->{'property'}</label><input id="$results->{$key}->{'property_id'}" class="object_form_input object_form required"><button class="object_form object_remove_property_button">Remove</button>
			);
		}
		print "Content-type: text/html\n\n";
		print $data;
	} elsif ($vars->{'mode'} eq "add_property_field"){
		my $property = $vars->{'property'};
		$query = "select * from property where pid = '$property';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchrow_hashref;
		$data = qq(<br><label class="object_form_label object_form">$results->{'property'}</label><input id="$results->{'pid'}" class="object_form_input object_form required"><button class="object_form object_remove_property_button">Remove</button>);
		print "Content-type: text/html\n\n";
		print $data;
		
	} elsif ($vars->{'mode'} eq "create_object"){
		$query = "select insert_object('true','$vars->{'type'}','$vars->{'company'}');";
		$sth = $dbh->prepare($query);
		$sth->execute;
		warn $DBI::errstr;

		for($vars->{'value'},$vars->{'property'}){
			$_ =~ s/:$//;
		}

		my @value = split(":",$vars->{'value'});
		my @property = split(":",$vars->{'property'});
		for (my $i = 0; $i <= $#value; $i++){
			$value[$i] =~ s/'/''/g;
			$query = "select insert_object_value('$value[$i]','$property[$i]')";
			$sth = $dbh->prepare($query);
			$sth->execute;
			warn $DBI::errstr;
			warn $query;
		}
		print "Content-type: text/html\n\n";
		print "0";
	} elsif ($vars->{'mode'} eq "current"){
		$query ="select object.oid as object, object.active, value.value, property.property, type.type, company.name as company from object join object_type on object.oid = object_type.object_id join type on type.tid = object_type.type_id join object_value on object.oid = object_value.object_id join value on object_value.value_id = value.vid join property_value on object_value.value_id = property_value.value_id join property on property_value.property_id = property.pid join object_company on object.oid = object_company.object_id join company on object_company.company_id = company.cpid;";
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this!";
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
