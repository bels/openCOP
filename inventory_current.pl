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
	my $vars = $q->Vars;
	my $query;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $data;
	foreach my $key (keys %$vars){
		chomp $vars->{$key};
	}
	$query = "select object_value.id as ovid, object.id as object, object.active, value.value, property.property from object join object_value on object.id = object_value.object_id join value on object_value.value_id = value.id join value_property on value.id = value_property.value_id join property on value_property.property_id = property.id;";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $object = $sth->fetchall_hashref('ovid');

	my $new_object = {};
	foreach my $key (keys %$object){
		$new_object->{$object->{$key}->{'object'}}->{$object->{$key}->{'property'}} =[ $object->{$key}->{'value'},$object->{$key}->{'ovid'}];
	}
	my @hash_order = keys %$new_object;
	
	@hash_order = sort(@hash_order);

	print "Content-type: text/html\n\n";

	if($vars->{'mode'} eq "by_company"){
		my $cpid = $vars->{'cpid'};

#		$query = "select value from value where id = (select value_property.value_id from value_property join object_value on value_property.value_id = object_value.value_id where property_id = (select (select id from property where property = 'company')) and object_value.object_id = '$cpid');";
		
		print qq(
		<table id="object_summary_header">
			<thead>
				<tr id="object_summary_header_row" class="header_row">
					<th id="object_id" class="header_row_item">ID</th>
					<th id="object_name" class="header_row_item">Name</th>
					<th id="object_type" class="header_row_item">Type</th>
				</tr>
			</thead>
		<tbody id="table_body">
		);
		foreach my $element (@hash_order)
		{
			my $type;
			my $name;

			if ($new_object->{$element}->{'type'}[0]){
				$query = "select template,id from template where id = '$new_object->{$element}->{'type'}[0]';";
				$sth = $dbh->prepare($query);
				$sth->execute;
				my $tid = $sth->fetchrow_hashref;
				$type = $tid->{'template'};
			}

			if ($new_object->{$element}->{'company'}[0] == $cpid){
				print qq(
					<tr class="object_row">
						<td class="row_object object_id">$element</td>
						<td class="row_object object_name">$new_object->{$element}->{'name'}[0]</td>
						<td class="row_object object_type">$type</td>
					</tr>
				);
			}
		}
		print qq(</tbody></table>);
	
	} elsif ($vars->{'mode'} eq "by_type"){
		my $tid = $vars->{'tid'};
		print qq(
		<table id="object_summary_header">
			<thead>
				<tr id="object_summary_header_row" class="header_row">
					<th id="object_id" class="header_row_item">ID</th>
					<th id="object_name" class="header_row_item">Name</th>
					<th id="object_company" class="header_row_item">Company</th>
				</tr>
			</thead>
		<tbody id="table_body">
		);
		foreach my $element (@hash_order)
		{
			my $company;
			my $name;
			if ($new_object->{$element}->{'company'}[0]){
				$query = "select name,id from company where id = '$new_object->{$element}->{'company'}[0]';";
				$sth = $dbh->prepare($query);
				$sth->execute;
				my $cpid = $sth->fetchrow_hashref;
				$company = $cpid->{'name'};
			}

			if ($new_object->{$element}->{'type'}[0] == $tid){
				print qq(
					<tr class="object_row">
						<td class="row_object object_id">$element</td>
						<td class="row_object object_name">$new_object->{$element}->{'name'}[0]</td>
						<td class="row_object object_company">$company</td>
					</tr>
				);
			}
		}
		print qq(</tbody></table>);		
	} elsif ($vars->{'mode'} eq "by_property"){
		my $data;
		if($vars->{'property'} eq "type"){
			$query = "select * from template;";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $id = $sth->fetchall_hashref('id');
	
			$data = qq(
				<select id="template_select" class="type_select">
					<option value="" selected="selected"></option>
			);
			foreach my $key (keys %$id){
				$data .= qq(
					<option value="$id->{$key}->{'id'}">$id->{$key}->{'template'}</option>
				);
			}
			$data .= qq(
				</select>
			);
		} elsif ($vars->{'property'} eq "company"){
			$query = "select id,name from company;";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $id = $sth->fetchall_hashref('id');
	
			$data = qq(<label for="company_select">Choose a company</label>
				<select id="company_select" class="type_select">
					<option value="" selected="selected"></option>
			);
			foreach my $key (keys %$id){
				$data .= qq(
					<option value="$id->{$key}->{'id'}">$id->{$key}->{'name'}</option>
				);
			}
			$data .= qq(
				</select>
			);
			
		} else {
			$data = qq(<label for="property_search">Refine search</label>
				<input id="property_search">
				<button id="property_search_button">Search</button>
			);
		}
		print $data;
	} elsif ($vars->{'mode'} eq "object_details"){
		my $object_id = $vars->{'object_id'};
		my $type;
		my $company;

		print qq(<h2>Item Details</h2>);
		print qq(<button id="update_object_button" object="$object_id">Save</button>);
		print qq(<button id="disable_object_button" object="$object_id">Disable</button>);
		print qq(<button id="delete_object_button" object="$object_id">Delete</button>);
		print qq(<form id="update_object_form">);
		foreach my $element (@hash_order){
			if($element == $object_id){
				foreach my $key (keys %{$new_object->{$element}}){
					if ($key eq "type"){
						$query = "select template,id from template where id = '$new_object->{$element}->{'type'}[0]';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $tid = $sth->fetchrow_hashref;
						$type = $tid->{'template'};
						print qq(
							<label class="object_detail" for=") . $key . qq(_input">$key</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$key}[1]" value="$type" readonly="readonly">
						);
					} elsif ($key eq "company"){
						$query = "select name,id from company where id = '$new_object->{$element}->{'company'}[0]';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $cpid = $sth->fetchrow_hashref;
						$company = $cpid->{'name'};
						print qq(
							<label class="object_detail" for=") . $key . qq(_input">$key</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$key}[1]" value="$company" readonly="readonly">
						);
					} elsif ($key eq "id"){
					}
					else {
						print qq(
							<label class="object_detail" for=") . $key . qq(_input">$key</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$key}[1]" value="$new_object->{$element}->{$key}[0]">
							<br>
						);
					}
				}
			}
		}
		print qq(
			</form>
		);

	} elsif ($vars->{'mode'} eq "init"){
		$query = "select id,property from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $pid = $sth->fetchall_hashref('id');

		$data = qq(<label for="by_property">Select criteria to display by</label>
			<select id="by_property">
				<option value="" selected="selected"></option>
		);
		my $i;
		my @pid;
		my @p;
		foreach(keys %$pid){
			push(@pid,$pid->{$_}->{'property'});
		}
		my @ppid = sort(@pid);
		foreach(keys %$pid){
			push(@p,$pid->{$_}->{'id'});
		}
		for ($i = 1; $i <= $#pid; $i++)
		{
			$data .= qq(<option value=$p[$i]>$ppid[$i]</option>);
		}
		$data .= qq(
			</select>
		);
		print $data;
	} elsif ($vars->{'mode'} eq "search"){
		my $cpid = $vars->{'cpid'};

		print qq(
		<table id="object_summary_header">
			<thead>
				<tr id="object_summary_header_row" class="header_row">
					<th id="object_id" class="header_row_item">ID</th>
					<th id="object_name" class="header_row_item">Name</th>
					<th id="object_type" class="header_row_item">Type</th>
					<th id="object_company" class="header_row_item">Company</th>
				</tr>
			</thead>
		<tbody id="table_body">
		);
		$query = "select object_value.id as ovid, object.id as object, object.active, value.value, property.property from object join object_value on object.id = object_value.object_id join value on object_value.value_id = value.id join value_property on value.id = value_property.value_id join property on value_property.property_id = property.id where value ilike '%" . $vars->{'search'} . "%';";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $o = $sth->fetchall_hashref('ovid');
	
		my $newer_object = {};
		foreach my $key (keys %$o){
			$newer_object->{$o->{$key}->{'object'}}->{$o->{$key}->{'property'}} = $o->{$key}->{'value'};
			warn $object->{$key}->{'property'};
			unless($object->{$key}->{'property'} eq $vars->{'property'}){
				delete($new_object->{$o->{$key}->{'object'}}->{'property'});
				delete($newer_object->{$o->{$key}->{'object'}}->{'property'});
			}
		}
	
		my @new_hash_order = keys %$newer_object;

		@new_hash_order = sort(@new_hash_order);

		foreach my $element (@new_hash_order)
		{
			my $type;
			my $company;
			my $name;
	
			if ($new_object->{$element}->{'type'}){
				$query = "select template,id from template where id = '$new_object->{$element}->{'type'}[0]';";
				$sth = $dbh->prepare($query);
				$sth->execute;
				my $tid = $sth->fetchrow_hashref;
				$type = $tid->{'template'};
			}

			if ($new_object->{$element}->{'company'}){
				$query = "select name,id from company where id = '$new_object->{$element}->{'company'}[0]';";
				$sth = $dbh->prepare($query);
				$sth->execute;
				my $cpid = $sth->fetchrow_hashref;
				$company = $cpid->{'name'};
			}

				print qq(
					<tr class="object_row">
						<td class="row_object object_id">$element</td>
						<td class="row_object object_name">$new_object->{$element}->{'name'}[0]</td>
						<td class="row_object object_type">$type</td>
						<td class="row_object object_company">$company</td>
					</tr>
				);
		}
		print qq(</tbody></table>);
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
