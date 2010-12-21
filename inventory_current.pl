#!/usr/bin/env perl

use strict;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use Data::Dumper;
use POSIX;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	my $object;
	my $new_object;
	my $data;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1}) or die "Database connection failed in $0";
	my $sth;

	if($vars->{'mode'} eq "by_company"){
		my $data = $q->Vars;
		my $page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

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
			$new_object->{$object->{$key}->{'object'}}->{$object->{$key}->{'vid'}} = {
					'value' => $object->{$key}->{'value'},
					'property' => $object->{$key}->{'property'},
			};
		}
		my $cpid = $vars->{'cpid'};
		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$new_object;
		} else {
			@ordered = sort { $b <=> $a } keys %$new_object;
		}
		my @innerXML;
		my $count = 0;
		foreach my $row (@ordered){
				my $type;
				my $name;
			foreach (keys %{$new_object->{$row}}){
				if ($new_object->{$row}->{$_}->{'property'} eq "type"){
					$query = "select template,id from template where id = '$new_object->{$row}->{$_}->{'value'}';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $tid = $sth->fetchrow_hashref;
					$type = $tid->{'template'};				
				}
	
				if ($new_object->{$row}->{$_}->{'property'} eq "name"){
					$new_object->{$row}->{'name'} = $new_object->{$row}->{$_}->{'value'};
				}
				if ($new_object->{$row}->{$_}->{'property'} eq "company" && $new_object->{$row}->{$_}->{'value'} == $cpid){
					$new_object->{$row}->{'company'} = $new_object->{$row}->{$_}->{'value'};
				}
			}
				if($new_object->{$row}->{'company'} == $cpid){
					$innerXML[$count] .= "<row id='" . $row . "'>";
					$innerXML[$count] .= "<cell>" . $row . "</cell>";
					$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'name'} . "</cell>";
					$innerXML[$count] .= "<cell>" . $type . "</cell>";
					$innerXML[$count] .= "</row>";
					$count++;
				}			
		}

		my $total_pages;
		if( $count > 0 && $limit > 0) {
			$total_pages = ceil($count/$limit); 
		} else { 
			$total_pages = 0;
		} 
		if($page > $total_pages){
			$page=$total_pages;
		}
		my $start = $limit * $page - $limit;
		if($start<0){$start=0};
		$limit = $start + $limit;
		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		for(my $i = $start; $i < $limit; $i++){
			$xml .= $innerXML[$i];
		}
		$xml .= "</rows>";
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;
	} elsif ($vars->{'mode'} eq "by_type"){
		my $tid = $vars->{'tid'};
		my $data = $q->Vars;
		my $page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

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
			$new_object->{$object->{$key}->{'object'}}->{$object->{$key}->{'vid'}} = {
					'value' => $object->{$key}->{'value'},
					'property' => $object->{$key}->{'property'},
			};
		}
		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$new_object;
		} else {
			@ordered = sort { $b <=> $a } keys %$new_object;
		}
		my @innerXML;
		my $count = 0;
		foreach my $row (@ordered){
			my $company;
			my $name;
			foreach (keys %{$new_object->{$row}}){
				if ($new_object->{$row}->{$_}->{'property'} eq "company"){
					$query = "select name,id from company where id = '$new_object->{$row}->{$_}->{'value'}';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $cpid = $sth->fetchrow_hashref;
					$company = $cpid->{'name'};
				}
				if ($new_object->{$row}->{$_}->{'property'} eq "name"){
					$new_object->{$row}->{'name'} = $new_object->{$row}->{$_}->{'value'};
				}
				if ($new_object->{$row}->{$_}->{'property'} eq "type" && $new_object->{$row}->{$_}->{'value'} == $tid){
					$new_object->{$row}->{'type'} = $new_object->{$row}->{$_}->{'value'};
				}
			}
			if($new_object->{$row}->{'type'} == $tid){
				$innerXML[$count] .= "<row id='" . $row . "'>";
				$innerXML[$count] .= "<cell>" . $row . "</cell>";
				$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'name'} . "</cell>";
				$innerXML[$count] .= "<cell>" . $company . "</cell>";
				$innerXML[$count] .= "</row>";
				$count++;
			}			
		}

		my $total_pages;
		if( $count > 0 && $limit > 0) {
			$total_pages = ceil($count/$limit); 
		} else { 
			$total_pages = 0;
		} 
			if($page > $total_pages){
		$page=$total_pages;
		}
		my $start = $limit * $page - $limit;
		if($start<0){$start=0};
		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		for(my $i = $start; $i < $limit; $i++){
			$xml .= $innerXML[$i];
		}
		$xml .= "</rows>";
		warn $xml;
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;
	} elsif ($vars->{'mode'} eq "by_property"){
		my $data;
		if($vars->{'property'} eq "type"){
		print "Content-type: text/html\n\n";
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
		print "Content-type: text/html\n\n";
			$query = "select id,name from company where not deleted";
			$sth = $dbh->prepare($query);
			$sth->execute;
			my $results = $sth->fetchall_hashref('name');
	
			$data = qq(<label for="company_select">Choose a company</label>
				<select id="company_select" class="type_select styled_form_element">
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
		print "Content-type: text/html\n\n";
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
			$new_object->{$object->{$key}->{'object'}}->{$object->{$key}->{'vid'}} = {
					'value' => $object->{$key}->{'value'},
					'property' => $object->{$key}->{'property'},
			};
		}

		print "Content-type: text/html\n\n";

		print qq(<h2>Item Details</h2>);
		print qq(<img src="images/save.png" class="image_button" id="update_object_button" object="$object_id" alt="Save">);
		print qq(<img src="images/add_property.png" class="add_property image_button" alt="Add Property">);
		print qq(<img src="images/disable.png" class="image_button" id="disable_object_button" object="$object_id" alt="Disable">);
		print qq(<img src="images/delete.png" class="image_button" id="delete_object_button" object="$object_id" alt="Delete">);
		print qq(<img src="images/cancel.png" class="image_button" id="cancel" object="$object_id" alt="Cancel">);
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
					if ($new_object->{$element}->{$ppid[$i]}->{'property'} eq "type"){
						$query = "select template,id from template where id = '$new_object->{$element}->{$ppid[$i]}->{'value'}';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $tid = $sth->fetchrow_hashref;
						$type = $tid->{'template'};
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}->{'property'} . qq(_input">$new_object->{$element}->{$ppid[$i]}->{'property'}</label>
							<input class="object_detail styled_form_element" type="text" id="$new_object->{$element}->{$ppid[$i]}->{'value'}" value="$type" readonly="readonly"><br>
						);
					} elsif ($new_object->{$element}->{$ppid[$i]}->{'property'} eq "company"){
						$query = "select name,id from company where id = '$new_object->{$element}->{$ppid[$i]}->{'value'}';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $cpid = $sth->fetchrow_hashref;
						$company = $cpid->{'name'};
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}->{'property'} . qq(_input">$new_object->{$element}->{$ppid[$i]}->{'property'}</label>
							<input class="object_detail styled_form_element" type="text" id="$new_object->{$element}->{$ppid[$i]}->{'value'}" value="$company" readonly="readonly"><br>
						);
					} elsif ($ppid[$i] eq "id"){
					}
					else {
						print qq(
							<label class="object_detail" for=") . $new_object->{$element}->{$ppid[$i]}->{'property'} . qq(_input">$new_object->{$element}->{$ppid[$i]}->{'property'}</label>
							<input class="object_detail styled_form_element" type="text" id="$ppid[$i]" value="$new_object->{$element}->{$ppid[$i]}->{'value'}">
							<img src="images/minus.png" class="del_property image_button" alt="Remove"><br>
						);
					}
				}
			}
		}
		print qq(
			</form>
		);

	} elsif ($vars->{'mode'} eq "init"){
		print "Content-type: text/html\n\n";
		$query = "select id,property from property;";
		$sth = $dbh->prepare($query);
		$sth->execute;
		my $pid = $sth->fetchall_hashref('property');

		$data = qq(<label for="by_property">Select criteria to display by</label>
			<select id="by_property" class="styled_form_element">
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
		print "Content-type: text/html\n\n";
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
			unless($pid->{$ppid[$i]}->{'property'} eq "name" || $pid->{$ppid[$i]}->{'property'} eq "company" || $pid->{$ppid[$i]}->{'property'} eq "type"){
				$data .= qq(<option value=$pid->{$ppid[$i]}->{'id'}>$pid->{$ppid[$i]}->{'property'}</option>);
			}
		}
		$data .= qq(
			</select>
		);
		print $data;
	} elsif ($vars->{'mode'} eq "search"){
		my $data = $q->Vars;
		my $page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

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
			$new_object->{$object->{$key}->{'object'}}->{$object->{$key}->{'vid'}} = {
					'value' => $object->{$key}->{'value'},
					'property' => $object->{$key}->{'property'},
			};
		}
		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$new_object;
		} else {
			@ordered = sort { $b <=> $a } keys %$new_object;
		}
		my @innerXML;
		my $count = 0;
		foreach my $row (@ordered){
			my $company;
			my $type;
			my $name;
			foreach (keys %{$new_object->{$row}}){
				if ($new_object->{$row}->{$_}->{'property'} eq "company"){
					$query = "select name,id from company where id = '$new_object->{$row}->{$_}->{'value'}';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $cpid = $sth->fetchrow_hashref;
					$company = $cpid->{'name'};
					$new_object->{$row}->{'company'} = $company;
				} elsif ($new_object->{$row}->{$_}->{'property'} eq "type"){
					$query = "select template,id from template where id = '$new_object->{$row}->{$_}->{'value'}';";
					$sth = $dbh->prepare($query);
					$sth->execute;
					my $tid = $sth->fetchrow_hashref;
					$type = $tid->{'template'};
					$new_object->{$row}->{'type'} = $type;
				}
				if ($new_object->{$row}->{$_}->{'property'} eq "name"){
					$new_object->{$row}->{'name'} = $new_object->{$row}->{$_}->{'value'};
				}
			}
				$innerXML[$count] .= "<row id='" . $row . "'>";
				$innerXML[$count] .= "<cell>" . $row . "</cell>";
				$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'name'} . "</cell>";
				$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'type'} . "</cell>";
				$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'company'} . "</cell>";
				$innerXML[$count] .= "</row>";
				$count++;
		}

		my $total_pages;
		if( $count > 0 && $limit > 0) {
			$total_pages = ceil($count/$limit); 
		} else { 
			$total_pages = 0;
		} 
			if($page > $total_pages){
		$page=$total_pages;
		}
		my $start = $limit * $page - $limit;
		if($start<0){$start=0};
		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
		$xml .= "<rows>";
		$xml .= "<page>$page</page>";
		$xml .= "<total>$total_pages</total>";
		$xml .= "<records>$count</records>";
		for(my $i = $start; $i < $limit; $i++){
			$xml .= $innerXML[$i];
		}
		$xml .= "</rows>";
		warn $xml;
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}

