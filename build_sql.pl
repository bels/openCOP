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
use ReportFunctions;
use JSON;
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
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	my $report = ReportFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $reports = $report->view(id => $id);

	my $vars = $q->Vars;
	my $name = $vars->{'report_name'};

	my $object = from_json($vars->{'data'});
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
	my $query;
	my @prepare_array;
	my @columns;
	$query = "select distinct(object) from inventory ";
		if(defined(@{$object->{'where'}}[0])){
			if(@{$object->{'where'}}[0]->{'value'} eq "and" || @{$object->{'where'}}[0]->{'value'} eq "or"){
				shift(@{$object->{'where'}});
			}
			$query .= "where (property = ? and value @{$object->{'where'}}[1]->{'value'} ?) ";
			push(@prepare_array,@{$object->{'where'}}[0]->{'value'});
			push(@columns,@{$object->{'where'}}[0]->{'value'});
			if(@{$object->{'where'}}[1]->{'value'} eq "like"){
				@{$object->{'where'}}[2]->{'value'} = "%" . @{$object->{'where'}}[2]->{'value'} . "%";
			}
			push(@prepare_array,@{$object->{'where'}}[2]->{'value'});
			for(my $i = 0; $i <= 2; $i++){
				shift(@{$object->{'where'}});
			}
			while(@{$object->{'where'}}){
				$query .= " @{$object->{'where'}}[0]->{'value'} ( property = ? and value @{$object->{'where'}}[2]->{'value'} ?) ";
				push(@prepare_array,@{$object->{'where'}}[1]->{'value'});
				push(@columns,@{$object->{'where'}}[1]->{'value'});
				if(@{$object->{'where'}}[2]->{'value'} eq "like"){
					@{$object->{'where'}}[3]->{'value'} = "%" . @{$object->{'where'}}[3]->{'value'} . "%";
				}
				push(@prepare_array,@{$object->{'where'}}[3]->{'value'});
				for(my $i = 0; $i <= 3; $i++){
					shift(@{$object->{'where'}});
				}
			}
		}

	$query .= ";";

	my $store = $query;
	my $sth = $dbh->prepare($query);
	$sth->execute(@prepare_array);
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

	if($vars->{'mode'} eq "save"){
		print "Content-type: text/html\n\n";
		my $check = "select count(*) from reports where name = ?;";
		my $sth = $dbh->prepare($check);
		$sth->execute($name);
		my $result = $sth->fetchrow_hashref;
		unless($result->{'count'}){ # No reports already saved with that name.
			my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});
			my $insert = "select insert_reports(?,?,?);";
			$sth = $dbh->prepare($insert);
			$sth->execute($store,$name,$id);
			my $report = $sth->fetchrow_hashref;
			if(defined(@{$object->{'groups'}}[0])){
				$insert = "insert into reports_aclgroup (report_id,aclgroup_id,aclread) values(?,?,?);";
				$sth = $dbh->prepare($insert);
				foreach(@{$object->{'groups'}}){
					$sth->execute($report->{'insert_reports'},$_->{'selected'},"true");
				}
			}
			print "0";
		} else { # Duplicate detected.
			print "1";
		}
	} elsif($vars->{'mode'} eq "run"){
		print "Content-type: text/html\n\n";
		print "2";
	#	warn $query;
	#	warn Dumper $new_object;
		my $columns;
		my (@ordered, $count, @innerXML);
		@ordered = sort { $a <=> $b } keys %$new_object;

		foreach my $row (@ordered){
				my $type;
				my $name;
			foreach (keys %{$new_object->{$row}}){
				if(defined($new_object->{$row}->{$_}->{'value'}) && $new_object->{$row}->{$_}->{'value'} ne ""){
					$columns->{$new_object->{$row}->{$_}->{'property'}} = $new_object->{$row}->{$_}->{'property'};
				}
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
			}
					$innerXML[$count] .= "<row id='" . $row . "'>";
					$innerXML[$count] .= "<cell>" . $row . "</cell>";
					$innerXML[$count] .= "<cell>" . $new_object->{$row}->{'name'} . "</cell>";
					$innerXML[$count] .= "<cell>" . $type . "</cell>";
					$innerXML[$count] .= "</row>";
					$count++;
		}

#		my $xml = "<?xml version='1.0' encoding='utf-8'?>";
#		$xml .= "<rows>";
#		$xml .= "<page>$page</page>";
#		$xml .= "<total>$total_pages</total>";
#		$xml .= "<records>$count</records>";
#		for(my $i = $start; $i < $limit; $i++){
#			$xml .= $innerXML[$i];
#		}
#		$xml .= "</rows>";
#		print "Content-type: text/xml;charset=utf-8\n\n";
#		print $xml;


#		foreach my $key (keys %$results){
#			foreach my $pkey (keys %{$results->{$key}}){
#				$columns->{$pkey} = $pkey;
#			}
#		}

	#	warn Dumper $columns;
	#	warn Dumper $results;

		my @styles = (
			"styles/ui.jqgrid.css",
			"styles/display_report.css"
		);
		my @javascripts = (
			"javascripts/grid.locale-en.js",
			"javascripts/jquery.jqGrid.min.js",
			"javascripts/jquery.download.js",
			"javascripts/jquery.validate.js",
			"javascripts/jquery.blockui.js",
			"javascripts/jquery.json-2.2.js",
			"javascripts/jquery.mousewheel.js",
			"javascripts/mwheelIntent.js",
			"javascripts/main.js",
		#	"javascripts/display_report.js"
		);
		my $title = $config->{'company_name'} . " - Custom Report";
		my $file = "display_report.tt";
		my $vars = {
			'title' => $title,
			'styles' => \@styles,
			'javascripts' => \@javascripts,
			'company_name' => $config->{'company_name'},
			 logo => $config->{'logo_image'},
			sorted_hash => \@ordered,
			columns => $columns,
			query => $store,
			reports => $reports,
			is_admin => $user->is_admin(id => $id),
			report_name => $name,
			prepare_array => \@prepare_array,
		};

		my $template = Template->new();
		$template->process($file,$vars) || die $template->error();
	} else {
		print "Content-type: text/html\n\n";
		warn "What? How did you even get here?";
	}
} elsif($authenticated == 2){
        print $q->redirect(-URL => $config->{'index_page'})
} else {
	print $q->redirect(-URL => $config->{'index_page'});
}
