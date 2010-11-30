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
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $query;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $data;
	my $used_properties;
	my @used_properties_order;

	my $vars = $q->Vars;
	if ($vars->{'mode'} eq "init"){
		my $type = $vars->{'type'};
		if($type){
			$query = "select property.property,template_property.id,template_property.property_id from template_property join property on template_property.property_id = property.id where template_id = '$type';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			$used_properties = $sth->fetchall_hashref('id');
			@used_properties_order = sort (keys %$used_properties);
		}

		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $all_properties  = $sth->fetchall_hashref('id');
		my @all_properties_order = sort (keys %$all_properties);
		my @used_properties;

		$data .= qq(
			<select id="associate_tp" class="multiselect" multiple="multiple" name="tp_select_array[]">
		);



		if(defined($used_properties)){
			my $i;
			my @pid = ['null'];
			my @p = ['null'];
			foreach(keys %$used_properties){
				push(@pid,$used_properties->{$_}->{'property'});
			}
			my @ppid = sort(@pid);
			foreach(keys %$used_properties){
				push(@p,$used_properties->{$_}->{'property_id'});
			}
			for ($i = 1; $i <= $#pid; $i++)
			{
				unless($used_properties->{$i}->{'property'} eq "type" || $used_properties->{$i}->{'property'} eq "company" || $used_properties->{$i}->{'property'} eq "name") {
					push(@used_properties,$used_properties->{$i}->{'property_id'});
					$data .= qq(<option selected="selected" value=$p[$i]>$ppid[$i]</option>);
				}
			}
		}

		foreach my $key (@all_properties_order){
			foreach (@used_properties){
				if($_ =~ m/$all_properties->{$key}->{'id'}/) {
					delete($all_properties->{$key});
				}
			}
		}

		if(defined($all_properties)){
			my $i;
			my @pid = ['null'];
			my @p = ['null'];
			foreach(keys %$all_properties){
				push(@pid,$all_properties->{$_}->{'property'});
			}
			my @ppid = sort(@pid);
			foreach(keys %$all_properties){
				push(@p,$all_properties->{$_}->{'id'});
			}
			for ($i = 1; $i <= $#pid; $i++)	{
				unless($all_properties->{$i}->{'property'} eq "type" || $all_properties->{$i}->{'property'} eq "company" || $all_properties->{$i}->{'property'} eq "name") {
					$data .= qq(<option value=$p[$i]>$ppid[$i]</option>);
				}
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
			$query = "delete from template_property where template_id = '$type' and property_id = '$i';";
			$sth = $dbh->prepare($query);
			$sth->execute;
		}

		for my $i (@selected) {
			$query = "select count(*) from template_property where template_id = '$type' and property_id = '$i';";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $count = $sth->fetchrow_hashref;
			unless($count->{'count'}){
				$query = "insert into template_property(template_id,property_id) values('$type','$i');";
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
		$query = "select * from template;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('id');
		$data = qq(
				<select id="type_select" class="type_select">
					<option value="" selected="selected"></option>
		);

		my $i;
		my @pid = ['null'];
		my @p = ['null'];
		foreach(keys %$results){
			push(@pid,$results->{$_}->{'template'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$results){
			push(@p,$results->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)	{
			$data .= qq(<option value=$p[$i]>$ppid[$i]</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "object_onload"){
		$query = "select * from template;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('id');

		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $properties = $sth->fetchall_hashref('id');

		$query = "select * from company where hidden = false;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $companies= $sth->fetchall_hashref('id');

		$query = "select id,property from property where property = 'type' or property = 'company' or property = 'name';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $special_case = $sth->fetchall_hashref('property');

		$data = qq(
				<form id="add_object_form">
					<div id="object_type_append_div">
					<div id="add_top_header" class="header_text">
					<span id="add_top_header_text">Create new objects</span>
				</div>
					<label for="object_type_select" class="add type_select">Create </label>
					<select id="object_type_select">
						<option value="" selected="selected"></option>
		);

		my $i;
		my @pid = ['null'];
		my @p = ['null'];
		foreach(keys %$results){
			push(@pid,$results->{$_}->{'template'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$results){
			push(@p,$results->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)	{
			$data .= qq(<option tpid="$special_case->{'type'}->{'id'}" value=$p[$i]>$ppid[$i]</option>);
		}


		$data .= qq(	</select>);

		$data .= qq(	
				<div id="company_select_div" class="select_div">
					<label for="object_company_select" class="add company_select">Company</label>
					<select id="object_company_select" class="company_select">
						<option value="" selected="selected"></option>
		);
		@pid = ['null'];
		@p = ['null'];
		foreach(keys %$companies){
			push(@pid,$companies->{$_}->{'name'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$companies){
			push(@p,$companies->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)	{
			$data .= qq(<option cpid="$special_case->{'company'}->{'id'}" value=$p[$i]>$ppid[$i]</option>);
		}
		$data .= qq(	</select>
				</div>
		);

		$data .= qq(
				<div id="object_name_input_div">
					<label for="object_name" class="add">Name </label>
					<input npid="$special_case->{'name'}->{'id'}" id="object_name" type="text">
				</div>
		);

		$data .= qq(
				
				<div id="property_select_div" class="select_div">
				<label for="object_property_select" class="add property_select">Add new property </label>
				<select id="object_property_select" class="property_select">
					<option value="" selected="selected"></option>
		);
		@pid = ['null'];
		@p = ['null'];
		foreach(keys %$properties){
			push(@pid,$properties->{$_}->{'property'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$properties){
			push(@p,$properties->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)	{
			unless($ppid[$i] eq "company" || $ppid[$i] eq "type" || $ppid[$i] eq "name"){
				$data .= qq(<option value=$p[$i]>$ppid[$i]</option>);
			}
		}
		$data .= qq(	</select>
				<button id="submit_add_property_button" class="submit_button left_add_object">Add Property</button>
				</div>
		);

		$data .= qq(
					<button id="submit_create_object_button" class="submit_button left_add_object">Create Inventory Object</button>
					</div>
				</form>
		);
		
		print $data;
	} elsif ($vars->{'mode'} eq "onload_more"){
		$query = "select * from template;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('id');
		$data = qq(
				<select id="del_tp" class="type_select">
					<option value="" selected="selected"></option>
		);

		my $i;
		my @pid = ['null'];
		my @p = ['null'];
		foreach(keys %$results){
			push(@pid,$results->{$_}->{'template'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$results){
			push(@p,$results->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)	{
			$data .= qq(<option value=$p[$i]>$ppid[$i]</option>);
		}

		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "load_properties"){
		$query = "select * from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('id');
		$data = qq(
				<select id="del_tp">
					<option value="" selected="selected"></option>
		);
		my @hash_order = sort (keys %$results);
		foreach my $key (@hash_order){
			$data .= qq(<option value="$results->{$key}->{'id'}">$results->{$key}->{'property'}</option>);
		}
		$data .= qq(</select>);
		print $data;
	} elsif ($vars->{'mode'} eq "populate_create_form"){
		my $type = $vars->{'type'};
		$query = "select property.property,template_property.id,template_property.property_id from template_property join property on template_property.property_id = property.id where template_id = '$type';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchall_hashref('id');
		my @hash_order = sort (keys %$results);
		my $i = $#hash_order;
		foreach my $key (@hash_order){
			$i++;
			$data .= qq(
				<br><label class="object_form_label object_form">$results->{$key}->{'property'}</label>	<input id="$results->{$key}->{'property_id'}" class="object_form_input object_form required">
			);
			$i--;
			$data .= qq(
				<button class="object_form object_remove_property_button">Remove</button>
			);
			$i++;
			$i++;
		}
		print "Content-type: text/html\n\n";
		print $data;
	} elsif ($vars->{'mode'} eq "add_property_field"){
		my $property = $vars->{'property'};
		$query = "select * from property where id = '$property';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $results = $sth->fetchrow_hashref;
		$data = qq(<br><label class="object_form_label object_form">$results->{'property'}</label><input id="$results->{'id'}" class="object_form_input object_form required"><button class="object_form object_remove_property_button">Remove</button>);
		print "Content-type: text/html\n\n";
		print $data;
		
	} elsif ($vars->{'mode'} eq "create_object"){
		$query = "select insert_object('true');";
		$sth = $dbh->prepare($query);
		$sth->execute;

		for($vars->{'value'},$vars->{'property'}){
			$_ =~ s/:$//;
		}
		
		my @value = split(":",$vars->{'value'});
		my @property = split(":",$vars->{'property'});
		foreach (@value){
			$_ =~ s/AbsolutelyNotAColon/:/g;
		}
		for (my $i = 0; $i <= $#value; $i++){
			$value[$i] =~ s/'/''/g;
			$query = "select insert_object_value('$value[$i]','$property[$i]')";
			$sth = $dbh->prepare($query);
			$sth->execute;
		}
		print "Content-type: text/html\n\n";
	} elsif ($vars->{'mode'} eq "delete_object"){
		$query = "delete from object where id = '$vars->{'object'}';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		print "Content-type: text/html\n\n";
		print "0";
	} elsif ($vars->{'mode'} eq "disable_object"){
		$query = "update object set active = false where id = '$vars->{'object'}';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		print "Content-type: text/html\n\n";
		print "0";
	} elsif ($vars->{'mode'} eq "update_object"){
		for($vars->{'value'},$vars->{'vid'}){
			$_ =~ s/:$//;
		}

		my @value = split(":",$vars->{'value'});
		my @vid = split(":",$vars->{'vid'});
		for (my $i = 0; $i <= $#value; $i++){
			$value[$i] =~ s/'/''/g;
			$query = "select update_object_value('$value[$i]','$vid[$i]')";
			$sth = $dbh->prepare($query);
			$sth->execute;
			warn $query;
		}
		print "Content-type: text/html\n\n";
		print "0";
	} else {
		print "Content-type: text/html\n\n";
		print "You should never see this!";
	}

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
