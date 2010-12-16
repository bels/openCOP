#!/usr/bin/env perl

use CGI::Carp qw(fatalsToBrowser);;
use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use DBI;
use Data::Dumper;

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
	} elsif($vars->{'mode'} eq "second_join") {
		my $error = 0;
		my $query;
		my $column_data;
	#	warn "Populating property select";
		my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
			$query = qq(
				select property from inventory;
			);
			my $sth = $dbh->prepare($query);
			$sth->execute;
			my $column = $sth->fetchall_hashref('property');
		#	warn Dumper $column;
			foreach (keys %$column){
			#	warn $_;
				$column_data .= qq(
					<option value="$_">$_</option>
				);
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
