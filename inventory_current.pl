#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use Data::Dumper;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'}); my $q = CGI->new(); my %cookie = 
$q->cookie('session');

my $authenticated = 0;

if(%cookie) {
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1) {
	my $vars = $q->Vars;
	my $query;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1}) or die "Database connection failed in $0";
	my $sth;
	my $data;
	foreach my $key (keys %$vars){
		chomp $vars->{$key};
	}
	$query = "
		select
			value.id as vid,
			object_value.id as ovid,
			object.id as object,
			object.active,
			value.value,
			property.property
		from
			object
		join
			object_value on object.id = object_value.object_id
		join
			value on object_value.value_id = value.id
		join
			value_property on value.id = value_property.value_id
		join
			property on value_property.property_id = property.id;
	";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $object = $sth->fetchall_hashref('vid');
	my $new_object = {};
	foreach my $key (keys %$object){
		$new_object->
			{$object->{$key}->{'object'}}->
				{$object->{$key}->{'vid'}} = [
					$object->{$key}->{'value'},
					$object->{$key}->{'vid'},
					$object->{$key}->{'property'},
				];
	}

	print "Content-type: text/html\n\n";

	if($vars->{'mode'} eq "by_company"){
		my $cpid = $vars->{'cpid'};

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
		foreach my $element (keys %$new_object)
		{
			my $type;
			my $name;

			foreach(keys %{$new_object->{$element}}){
				if ($new_object->{$element}->{$_}[2] eq "type"){
					$query = "select template,id from template where id = '$new_object->{$element}->{$_}[0]';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $tid = $sth->fetchrow_hashref;
					$type = $tid->{'template'};
				}
	
				if ($new_object->{$element}->{$_}[2] eq "name"){
					$new_object->{$element}->{'name'} = $new_object->{$element}->{$_}[0];
				}
				if ($new_object->{$element}->{$_}[2] eq "company" && $new_object->{$element}->{$_}[0] == $cpid){
					$new_object->{$element}->{'company'} = $new_object->{$element}->{$_}[0];
				}
			}
			warn $new_object->{$element}->{'company'};
			warn $cpid;
			if($new_object->{$element}->{'company'} == $cpid){
				print qq(
					<tr class="object_row">
						<td class="row_object object_id">$element</td>
						<td class="row_object object_name">$new_object->{$element}->{'name'}</td>
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
		foreach my $element (keys %$new_object)
		{
			my $company;
			my $name;

			foreach(keys %{$new_object->{$element}}){
				if ($new_object->{$element}->{$_}[2] eq "company"){
					$query = "select name,id from company where id = '$new_object->{$element}->{$_}[0]';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $cpid = $sth->fetchrow_hashref;
					$company = $cpid->{'name'};
				} elsif ($new_object->{$element}->{$_}[2] eq "name"){
					$new_object->{$element}->{'name'} = $new_object->{$element}->{$_}[0];
				} elsif ($new_object->{$element}->{$_}[2] eq "type" && $new_object->{$element}->{$_}[0] == $tid){
					$new_object->{$element}->{'type'} = $new_object->{$element}->{$_}[0];
				}


			}
			if ($new_object->{$element}->{'type'} == $tid){
				print qq(
					<tr class="object_row">
						<td class="row_object object_id">$element</td>
						<td class="row_object object_name">$new_object->{$element}->{'name'}</td>
						<td class="row_object object_type">$company</td>
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
			my $results = $sth->fetchall_hashref('template');
	
			$data = qq(
				<select id="template_select" class="type_select">
					<option value="" selected="selected"></option>
			);
			my $i;
			my @pid;
			foreach(keys %$results){
				push(@pid,$_);
			}
			my @ppid = sort({lc($a) cmp lc($b)} @pid);
			for ($i = 0; $i <= $#ppid; $i++){
				$data .= qq(<option value=$results->{$ppid[$i]}->{'id'}>$ppid[$i]</option>);
			}

			$data .= qq(
				</select>
			);
		} elsif ($vars->{'property'} eq "company"){
			$query = "select id,name from company;";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $results = $sth->fetchall_hashref('name');
	
			$data = qq(<label for="company_select">Choose a company</label>
				<select id="company_select" class="type_select">
					<option value="" selected="selected"></option>
			);
			my $i;
			my @pid;
			foreach(keys %$results){
				push(@pid,$results->{$_}->{'name'});
			}
			my @ppid = sort({lc($a) cmp lc($b)} @pid);
			for ($i = 0; $i <= $#ppid; $i++){
				$data .= qq(<option value=$results->{$ppid[$i]}->{'id'}>$ppid[$i]</option>);
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
		print qq(<button class="add_property">Add Property</button>);
		print qq(<form id="update_object_form">);

		foreach my $element (keys %$new_object){
			if($element == $object_id){
				my $i;
				my @pid;
				foreach(keys %{$new_object->{$element}}){
					push(@pid,$_);
				}
				my @ppid = sort({lc($a) cmp lc($b)} @pid);
				for ($i = 0; $i <= $#ppid; $i++){
					if ($new_object->{$element}->{$ppid[$i]}[2] eq "type"){
						$query = "select template,id from template where id = '$new_object->{$element}->{$ppid[$i]}[0]';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $tid = $sth->fetchrow_hashref;
						$type = $tid->{'template'};
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}[2] . qq(_input">$new_object->{$element}->{$ppid[$i]}[2]</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$ppid[$i]}[0]" value="$type" readonly="readonly"><br>
						);
					} elsif ($new_object->{$element}->{$ppid[$i]}[2] eq "company"){
						$query = "select name,id from company where id = '$new_object->{$element}->{$ppid[$i]}[0]';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $cpid = $sth->fetchrow_hashref;
						$company = $cpid->{'name'};
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}[2] . qq(_input">$new_object->{$element}->{$ppid[$i]}[2]</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$ppid[$i]}[0]" value="$company" readonly="readonly"><br>
						);
					} elsif ($ppid[$i] eq "id"){
					}
					else {
						#	<input class="object_detail" type="text" id="$p[$i][1]" value="$p[$i][0]">
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}[2] . qq(_input">$new_object->{$element}->{$ppid[$i]}[2]</label>
							<input class="object_detail" type="text" id="$new_object->{$element}->{$ppid[$i]}[1]" value="$new_object->{$element}->{$ppid[$i]}[0]">
							<button class="del_property">-</button><br>
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
		my $pid = $sth->fetchall_hashref('property');

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
		my @ppid = sort({lc($a) cmp lc($b)} @pid);
		for ($i = 0; $i <= $#ppid; $i++)
		{
			$data .= qq(<option value=$pid->{$ppid[$i]}->{'id'}>$pid->{$ppid[$i]}->{'property'}</option>);
		}
		$data .= qq(
			</select>
		);
		print $data;
	} elsif ($vars->{'mode'} eq "add_property"){
		$query = "select id,property from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $pid = $sth->fetchall_hashref('property');

		$data = qq(
			<select id="add_by_property" class="object_detail">
				<option value="" selected="selected"></option>
		);
		my $i;
		my @pid;
		foreach(keys %$pid){
			push(@pid,$pid->{$_}->{'property'});
		}
		my @ppid = sort({lc($a) cmp lc($b)} @pid);
		for ($i = 0; $i <= $#ppid; $i++)
		{
			$data .= qq(<option value=$pid->{$ppid[$i]}->{'id'}>$pid->{$ppid[$i]}->{'property'}</option>);
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
