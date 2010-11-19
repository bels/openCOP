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

	if(defined(@{$object->{'joins'}}[0])){
		for(my $i = 1; $i < @{$object->{'tables'}}; $i++){
			$query .= "join @{$object->{'tables'}}[$i]->{'value'} on @{$object->{'joins'}}[0]->{'value'} = @{$object->{'joins'}}[1]->{'value'} ";
			shift(@{$object->{'joins'}});
			shift(@{$object->{'joins'}});
		}
	}

	if(defined(@{$object->{'where'}}[0])){
		if(@{$object->{'where'}}[0]->{'value'} eq "and" || @{$object->{'where'}}[0]->{'value'} eq "or"){
			shift(@{$object->{'where'}});
		}
		$query .= "where (@{$object->{'where'}}[0]->{'value'} @{$object->{'where'}}[1]->{'value'} ?) ";
		if(@{$object->{'where'}}[1]->{'value'} eq "like"){
			@{$object->{'where'}}[2]->{'value'} = "%" . @{$object->{'where'}}[2]->{'value'} . "%";
		}
		push(@prepare_array,@{$object->{'where'}}[2]->{'value'});
		for(my $i = 0; $i <= 2; $i++){
			shift(@{$object->{'where'}});
		}
		while(@{$object->{'where'}}){
			$query .= " @{$object->{'where'}}[0]->{'value'} (@{$object->{'where'}}[1]->{'value'} @{$object->{'where'}}[2]->{'value'} ?) ";
			if(@{$object->{'where'}}[2]->{'value'} eq "like"){
				@{$object->{'where'}}[3]->{'value'} = "%" . @{$object->{'where'}}[3]->{'value'} . "%";
			}
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

	if($vars->{'mode'} eq "save"){
		print "Content-type: text/html\n\n";
		my $aclgroup;
		my $alias = $session->get_name_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
		my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
		my $id = $user->get_user_id(alias => $alias);
		my $name = $vars->{'report_name'};
		warn $name;
		my $insert = "insert into reports (report,name,aclgroup,owner) values(?,?,?,?);";
		my $sth = $dbh->prepare($insert);
		$sth->execute($query,$name,$aclgroup,$id);
		print "1";
	} elsif($vars->{'mode'} eq "run"){
		print "Content-type: text/html\n\n";
		print "2";
		my $sth = $dbh->prepare($query);
		$sth->execute(@prepare_array);
		my $results = $sth->fetchall_hashref(1);
		my @sorted_hash;
		my $columns = {};
		if(defined(@{$object->{'other'}}[0])){
			if(@{$object->{'other'}}[0]->{'value'} eq "asc"){
				@sorted_hash = sort {$a <=> $b} (keys %$results);
			} else {
				@sorted_hash = sort {$b <=> $a} (keys %$results);
			}
		} else {
			@sorted_hash = sort {$a <=> $b} (keys %$results);
		}

		foreach my $key (keys %$results){
			foreach my $pkey (keys %{$results->{$key}}){
				$columns->{$pkey} = $pkey;
			}
		}

		my @styles = ("styles/jquery.jscrollpane.css","styles/layout.css","styles/display_report.css");
		my @javascripts = ("javascripts/jquery.js","javascripts/main.js","javascripts/jquery.hoverIntent.minified.js","javascripts/jquery.validate.js","javascripts/jquery.blockui.js","javascripts/jquery.livequery.js","javascripts/jquery.json-2.2.js","javascripts/main.js","javascripts/jquery.mousewheel.js","javascripts/mwheelIntent.js","javascripts/jquery.jscrollpane.js","javascripts/jquery.tablesorter.js","javascripts/display_report.js");
		my $title = $config->{'company_name'} . " - Custom Report";
		my $file = "display_report.tt";

		my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'}, sorted_hash => \@sorted_hash, results => $results, columns => $columns};
	
		my $template = Template->new();
		$template->process($file,$vars) || die $template->error();
	} else {
		warn "What? How did you even get here?";
	}
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
