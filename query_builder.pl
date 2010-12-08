#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

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
	if($vars->{'mode'} eq "operator"){
		my $error = 0;
		my $operator = {
			"equals"	=>	"=",
			"greater_than"	=>	">",
			"less_than"	=>	"<",
			"like"		=>	"like",
			"not_like"	=>	"not like",
			"is"		=>	"is",
			"is_not"	=>	"is not",
		};
		my $operator_data = qq(
			<option value=""></option>
		);
		foreach (keys %$operator){
			$operator_data .= qq(
				<option value="$operator->{$_}">$operator->{$_}</option>
			);
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
			print $operator_data;
		}
	} elsif($vars->{'mode'} eq "table") {
		my $error = 0;
		my $table = {
			'helpdesk'	=>	"helpdesk",
			'object_value'	=>	"object_value",
			'object'	=>	"object",
			'value'		=>	"value",
			'value_property'=>	"value_property",
			'property'	=>	"property",
		};
		my $table_data = qq(
			<option value=""></option>
		);
		foreach (keys %$table){
			$table_data .= qq(
				<option value="$table->{$_}">$table->{$_}</option>
			);
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
			print $table_data;
		}
	} elsif($vars->{'mode'} eq "select_column") {
		my $error = 0;
		my $tablestring = $vars->{'tablestring'};
		$tablestring =~ s/:$//;
		my @table = split(":",$tablestring);
		my $query;
		my $column_data;

		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		my $column_data = qq(
			<option value="*">*</option>
		);

		foreach my $t (@table){
			$query = qq(
				select * from $t;
			);
			my $sth = $dbh->prepare($query);
			$sth->execute;
			my $column = $sth->fetchrow_hashref;
	
			foreach (keys %$column){
				$column_data .= qq(
					<option value="$t.$_">$t.$_</option>
				);
			}
		}

		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
			print $column_data;
		}
	} elsif($vars->{'mode'} eq "first_join") {
		my $error = 0;
		my $table = $vars->{'table'};
		my $column_data;

		if(defined($table)){
			my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
			my $query = qq(
				select * from $table;
			);
			my $sth = $dbh->prepare($query);
			$sth->execute;
			my $column = $sth->fetchrow_hashref;
	
			$column_data = qq(
			);
			foreach (keys %$column){
				$column_data .= qq(
					<option value="$table.$_">$table.$_</option>
				);
			}
		}
		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
			print $column_data;
		}
	} elsif($vars->{'mode'} eq "second_join") {
		my $error = 0;
		my $tablestring = $vars->{'tablestring'};
		$tablestring =~ s/:$//;
		my @table = split(":",$tablestring);
		my $query;
		my $column_data;

		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
		foreach my $t (@table){
			$query = qq(
				select * from $t;
			);
			my $sth = $dbh->prepare($query);
			$sth->execute;
			my $column = $sth->fetchrow_hashref;
	
			foreach (keys %$column){
				$column_data .= qq(
					<option value="$t.$_">$t.$_</option>
				);
			}
		}

		print "Content-type: text/html\n\n";
		if($error){
			print "1";
		} else {
			print "0";
			print $column_data;
		}
	} else {

	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
