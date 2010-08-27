#!/usr/bin/perl

# CCBOE Helpdesk Scripts
# Report.pm - Generate ticket reports from helpdesk database
# By Clark Buehler (cbuehler@ccboe.com)

package CCBOEHD::DateReport;
use base qw(CCBOEHD::Report);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;
use YAML;
use Data::Dumper;

##
## Overrides
##

sub setup
{
	my $self = shift;

	$self->mode_param('mode');
	$self->run_modes(
		$self->run_modes,
		'foo' => 'bar',
	);
	$self->start_mode('welcome');
	$self->load_config;
	$self->db_connect;
}


## 
## Interface functions
## 

sub custom_view{
	my $self = shift;

	my %form = $self->form_to_variables();
	$self->load_template($self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'custom'}->{'template'});
	$self->param('template')->param('self_url' => $self->query->url);

	$self->populate_params('report.pl');
	$self->set_self_url;

	my $y = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'});
	$self->param('report',$y);

	$self->fill_select_form($self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'custom'}->{'rmap'});


	return $self->param('template')->output();
}

sub report_view{
	my $self = shift;

	my %form = $self->form_to_variables;
	$self->load_template($self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'template'});
	$self->param('template')->param('self_url' => $self->query->url);

#die Data::Dumper::Dumper %form;
	$self->populate_params('report.pl');
	$self->set_self_url;

	my $y = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'});

	$self->param('report',$y);

	$self->fill_select_form;

	my $sql = $self->make_sql_from_form_submit(%form);

	$self->fill_results_loop($sql,$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'});

	if($self->param('template')->query(name => 'bookmarkable') && !$form{'bookmarked'}){
		my @bookmarkable;
		foreach my $k (keys %form){
				my %row;
				$row{'key'} = $k;
				$row{'value'} = $form{$k};
				push(@bookmarkable,\%row);
		}
		
		push(@bookmarkable,{'key' => 'bookmarked', 'value' => 1});
		$self->param('template')->param('bookmarkable',[@bookmarkable]);
	
	}

	return $self->param('template')->output();
}

sub date_view{
	my $self = shift;
	return qq(<html><head><title> Under construction </title></head><body><h1>Under construction</h1><p>Try back later.</p></body></html>);
}

## 
## Internal functions
## 

sub fill_loop{
	my $self = shift;
	my $loopname = shift;

	my $y = $self->param('report-welcome');

        my @col;

        foreach my $f (@{$y->{'fields'}}){
		my ($key) = keys %{$f};
		my %fields = %{$f->{$key}};

		my $sql;

		$sql .= "select ".($fields{'field'})." from ".($fields{'table'});

		if($fields{'where'} && defined($fields{'value'}) && $fields{'compare'}){
			my %cmp = $self->lookup_cmp(
					$y->{'comparisons'},
					$fields{'compare'},
				  );
			$sql .= " where ".($fields{'where'})." ".($cmp{'sql'})." ".($self->param('hddb')->quote($fields{'value'}));
		}

		if($fields{'sort'}){
			$sql .= " order by ".($fields{'sort'});
		}

		$sql .= ';';
		my $sth = $self->param('hddb')->prepare($sql);
		$sth->execute();

		my $selected = $self->school_from_ip; # Get the current school number, if any

		my @entries;
		while(my $data = $sth->fetchrow_hashref()){
			my %row;
			$row{'txt'} = $data->{'txt'};
			$row{'lbl'} = $data->{'lbl'};
			$row{'sel'} = '';
			$row{'sel'} = ' selected' if $data->{'sel'} eq $selected ;
			push(@entries,\%row);
		}
		$self->param('template')->param($fields{'varname'} => [@entries]);

        }

	my @now = localtime(time);

	my @bsec = $self->numeric_selector(0,59,0,'%02d');
	my @esec = $self->numeric_selector(0,59,$now[0],'%02d');

	my @bmin = $self->numeric_selector(0,59,0,'%02d');
	my @emin = $self->numeric_selector(0,59,$now[1],'%02d');

	my @bhr = $self->numeric_selector(0,23,0,'%02d');
	my @ehr = $self->numeric_selector(0,23,$now[2]+1,'%02d');

#die Data::Dumper::Dumper @now;
	my @bday = $self->numeric_selector(1,31,0,'%02d');
	my @eday = $self->numeric_selector(1,31,$now[3],'%02d');

	my @bmonth = $self->numeric_selector(1,12,0,'%02d');
	my @emonth = $self->numeric_selector(1,12,$now[4]+1,'%02d');

	my @byr = $self->numeric_selector(2001,$now[5]+1900,$now[5]+1900,'%4d');
	my @eyr = $self->numeric_selector(2001,$now[5]+1900,$now[5]+1900,'%4d');

	$self->param('template')->param('bsec' => [@bsec]);
	$self->param('template')->param('esec' => [@bsec]);

	$self->param('template')->param('bmin' => [@bmin]);
	$self->param('template')->param('emin' => [@emin]);

	$self->param('template')->param('bhour' => [@bhr]);
	$self->param('template')->param('ehour' => [@ehr]);

	$self->param('template')->param('bday' => [@bday]);
	$self->param('template')->param('eday' => [@eday]);

	$self->param('template')->param('bmonth' => [@bmonth]);
	$self->param('template')->param('emonth' => [@emonth]);

	$self->param('template')->param('byear' => [@byr]);
	$self->param('template')->param('eyear' => [@eyr]);


        return @col;

}

sub numeric_selector{
	my $self = shift;
	my $start = shift;
	my $end = shift;
	my $selected = shift;
	my $format = shift;

	my @entries;
	foreach my $n ($start..$end){
		my %row;
		$row{'txt'} = $n;
		$row{'lbl'} = sprintf($format, $n);
		$row{'sel'} = '';
		$row{'sel'} = ' selected' if $n eq $selected;
		push(@entries,\%row);
	}

	return @entries;
}


1;
