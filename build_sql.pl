#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;
use DBI;
use JSON;
use YAML;


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
	my $vars = $q->Vars;

	my $json = JSON->new;
	my $object = from_json($vars->{'data'});
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query;
	my @prepare_array;
#	$query = qq(
#		select * from @{$object->{'tables'}}[0]->{'value'};
#	);
#	my $sth = $dbh->prepare($query);
#	$sth->execute;
#	my $column = $sth->fetchrow_hashref;

	$query = "select ";
	for(my $i = 0; $i < @{$object->{'select_columns'}}; $i++){
		if(@{$object->{'select_columns'}}[$i]->{'value'} eq "*"){
			$query .= "@{$object->{'select_columns'}}[$i]->{'value'}, ";
		} else {
			$query .= "@{$object->{'tables'}}[0]->{'value'}.@{$object->{'select_columns'}}[$i]->{'value'}, ";
		}
	}
	$query =~ s/, $/ /;

	$query .= "from @{$object->{'tables'}}[0]->{'value'} ";

	YAML::DumpFile("json.yaml",$object);
	if(defined(@{$object->{'joins'}}[0])){
		for(my $i = 1; $i < @{$object->{'tables'}}; $i++){
			$query .= "join @{$object->{'tables'}}[$i]->{'value'} on @{$object->{'joins'}}[0]->{'value'} = @{$object->{'joins'}}[1]->{'value'} ";
			shift(@{$object->{'joins'}});
			shift(@{$object->{'joins'}});
		}
	}

	if(defined(@{$object->{'where'}}[0])){
		$query .= "where (@{$object->{'where'}}[0]->{'value'} @{$object->{'where'}}[1]->{'value'} ?) ";
		push(@prepare_array,@{$object->{'where'}}[2]->{'value'});
		for(my $i = 0; $i <= 2; $i++){
			shift(@{$object->{'where'}});
		}
		while(@{$object->{'where'}}){
			$query .= " @{$object->{'where'}}[0]->{'value'} (@{$object->{'where'}}[1]->{'value'} @{$object->{'where'}}[2]->{'value'} ?) ";
			push(@prepare_array,@{$object->{'where'}}[3]->{'value'});
			for(my $i = 0; $i <= 3; $i++){
				shift(@{$object->{'where'}});
			}
		}
	}

	if(defined(@{$object->{'other'}}[0])){
		$query .= "@{$object->{'other'}}[0]->{'name'} @{$object->{'other'}}[0]->{'value'}";
		for(my $i = 0; $i < 1; $i++){
			shift(@{$object->{'other'}});
		}
	}
	$query .= ";";
	warn $query;

#	for(@sorted_hash){
#		warn $_;
#	}

	if($vars->{'mode'} eq "save"){
		print "Content-type: text/html\n\n";
		my $aclgroup;
		my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		my $id = $user->get_user_id(alias => $alias);
		my $insert = "insert into reports (report,aclgroup,owner) values(?,?,?);";
		my $sth = $dbh->prepare($insert);
		$sth->execute($query,$aclgroup,$id);
	} elsif($vars->{'mode'} eq "run"){
		print "Content-type: text/html\n\n";
		my $sth = $dbh->prepare($query);
		$sth->execute(@prepare_array);
		my $results = $sth->fetchall_hashref(1);
		my @sorted_hash;
		if(defined(@{$object->{'other'}}[0])){
			if(@{$object->{'other'}}[0]->{'value'} eq "asc"){
				@sorted_hash = sort {$a <=> $b} (keys %$results);
			} else {
				@sorted_hash = sort {$b <=> $a} (keys %$results);
			}
		} else {
		@sorted_hash = sort {$a <=> $b} (keys %$results);
	}
	} else {
		warn "What? How did you even get here?";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
