#!/usr/bin/env perl

use strict;
use lib './libs';
use Ticket;
use CGI;
use SessionFunctions;
use JSON;
use UserFunctions;
use YAML;
use URI::Escape;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

my $ticket = Ticket->new(mode => "");

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user;
	my $alias;
	my $id;
	my $vars = $q->Vars;
	my $data;
	my $name = $vars->{'name'};
	$alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	$user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $sth;
	my $query;

	my @tickets;
	my $object = from_json($vars->{'object'});
	shift(@{$object});

	YAML::DumpFile('temp.yml',$object);

	my $step = 0;
	$query = "select create_wo(?)";
	$sth = $dbh->prepare($query);
	$sth->execute($name);
	my $wo_id = $sth->fetchrow_hashref;
	foreach my $i (@{$object}){
		foreach my $j (@{$i}){
				foreach (keys %$j){
					$j->{$_} = uri_unescape($j->{$_});
					$data->{$_} = $j->{$_};
					if($data->{$_} eq ""){
						$data->{$_} = "0";
					}
				}
		}
	#	$data->{'submitter'} = $user->get_user_id(alias => $alias);
	#	$data->{'notes'} = "";
	#	$data->{'customer'} = 0;
		$step++;

	#	if(defined($data->{'tech'})){
	#		$id = $user->get_user_info(alias => $data->{'tech'});
	#		$data->{'tech_email'} = $id->{'email'};
	#	}

	#	my $access = $ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data); #need to pass in hashref named data
	#	push(@tickets,$access->{'id'});
	#	warn @tickets;
		$query = "select insert_wo(
			?,
			?,
			?,
			?
		)";
		$sth = $dbh->prepare($query);
		$sth->execute($wo_id->{'create_wo'},$data->{'section'},$data->{'requires'},$step);
		foreach(@tickets){
		#	my $wo_id = $sth->fetchrow_hashref;
		}
	}
	print "Content-type: text/html\n\n";
	print "0";
#	if($access->{'error'}){
#		warn "Access denied to section " .  $data->{'section'} . " for user " . $data->{'submitter'};
#		print "1";
#		print "Access denied";
#	} else {
#		print "0";
#	}
}	
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
