#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use JSON;
use POSIX;
use Data::Dumper;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $data = $q->Vars;

	my $query = $data->{'query'};

	my $prepare_array = from_json $data->{'prepare_array'};
	warn $query;
#	foreach(@{$prepare_array}){
#		warn $_;
#	}
	my $sth = $dbh->prepare($query);
	$sth->execute(@{$prepare_array});
	my $results = $sth->fetchall_hashref('object');
	my $new_object = {};
	foreach(keys %$results){
		$query = "select * from objects(?);";
		$sth = $dbh->prepare($query);
		$sth->execute($_);
		my $new_results = $sth->fetchall_hashref('id');
		foreach my $key (keys %$new_results){
			$new_object->{$new_results->{$key}->{'object'}}->{$new_results->{$key}->{'id'}} = {
					'value' => $new_results->{$key}->{'value'},
					'property' => $new_results->{$key}->{'property'},
			};
		}
	}

#	warn Dumper $new_object;
		my $page = $data->{'page'};
		if(!$page){$page=1};
		my $limit = $data->{'rows'};
		if(!$limit){$limit=10};
		my $sidx = $data->{'sidx'};
		if(!$sidx){$sidx = 1};
		my $sord = $data->{'sord'};

		my @ordered;
		if($sord eq "asc"){
			@ordered = sort { $a <=> $b } keys %$new_object;
		} else {
			@ordered = sort { $b <=> $a } keys %$new_object;
		}
		my @innerXML;
		my $count = 0;

		my $columns;
		foreach my $row (@ordered){
			my $type;
			my $name;
			my @o_again = sort{$new_object->{$row}->{$a}->{'property'} cmp $new_object->{$row}->{$b}->{'property'} } keys %{$new_object->{$row}};
			foreach (@o_again){
#			foreach (keys %{$new_object->{$row}}){
				if(defined($new_object->{$row}->{$_}->{'value'}) && $new_object->{$row}->{$_}->{'value'} ne ""){
					$columns->{$new_object->{$row}->{$_}->{'property'}} = $new_object->{$row}->{$_}->{'property'};
				}
				if ($new_object->{$row}->{$_}->{'property'} eq "type"){
					if($new_object->{$row}->{$_}->{'value'} ne ""){
						$query = "select template,id from template where id = '$new_object->{$row}->{$_}->{'value'}';";
						$sth = $dbh->prepare($query);
						$sth->execute;
						my $tid = $sth->fetchrow_hashref;
						$type = $tid->{'template'};				
				#		$innerXML[$count] .= "<cell>" . $type . "</cell>";
					}
				} elsif ($new_object->{$row}->{$_}->{'property'} eq "name"){
					if($new_object->{$row}->{$_}->{'value'} ne ""){
				#		$new_object->{$row}->{'name'} = $new_object->{$row}->{$_}->{'value'};
				#		$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'name'} . "</cell>";
					}
				} else {
				#	$innerXML[$count] .= "<cell>" . $new_object->{$row}->{$_}->{'value'} . "</cell>";
				}				
			}
			$count++;			
		}
		foreach my $row (@ordered){
			$innerXML[$count] .= "<row id='" . $row . "'>";
			$innerXML[$count] .= "<cell>" . $row . "</cell>";
			foreach my $key (sort keys %$columns){
				my $value;
				foreach (keys %{$new_object->{$row}}){
					if($new_object->{$row}->{$_}->{'property'} eq $key){
						if ($new_object->{$row}->{$_}->{'property'} eq "type"){
							if($new_object->{$row}->{$_}->{'value'} ne ""){
								$query = "select template,id from template where id = '$new_object->{$row}->{$_}->{'value'}';";
								$sth = $dbh->prepare($query);
								$sth->execute;
								my $tid = $sth->fetchrow_hashref;
								$value = $tid->{'template'};				
							}
						} else {
								$value = $new_object->{$row}->{$_}->{'value'};
						}				

					}
				}
				$innerXML[$count] .= "<cell>" . $value . "</cell>";
			}
			$innerXML[$count] .= "</row>";
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
		print "Content-type: text/xml;charset=utf-8\n\n";
		print $xml;

} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
