#!/usr/bin/perl

package CCBOEHD::TestRP;
use base qw(CCBOEHD::Base);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;

##
## Overrides
##

sub setup
{
	my $self = shift;

	$self->param('template' => HTML::Template->new(
		filename => 'report_new.html',
		path => [
			'/home/collin/src/CCBOE/Templates',
		],
	));
	
	$self->start_mode('default');
	$self->mode_param('mode');
	$self->run_modes(
		'default' => 'basic_report',
		'report' => 'report',
	);
	$self->db_connect;
}


## 
## Interface functions
## 

sub basic_report{
	my $self = shift;
	# Set some default values that report() expects.
	return $self->report();
}

sub report{
	my $self = shift;

	$self->param('template')->param('self_url' => $self->query->url);

	my @names = $self->query->param;
# CONFIRMED. They do show up in order.
# We need
# column1, value1, comparison1, comparison1
# repeat
	my %form;
	my $dbg = '';
	my $column = '';
	my @coldata;
	foreach my $field (@names){
		my %query;
		if($field =~ /column/){
			$column = $self->query->param($field);
			$query{$column}->{'name'} = $column;
		} elsif($field =~ /andor/){
			if($query{$column}){
				$query{$column}->{'op'} = $self->query->param($field);
#				$query{$column}->{'op'} = 'eq';
			}
		} elsif($field =~ /value/){
			$query{$column}->{'value'} = $self->query->param($field);
		} elsif($field =~ /compar/){
			$query{$column}->{'comparison'} = $self->query->param($field);
		} else{
			#die "error";
		}
		push(@coldata,\%query);
#		$dbg .= $field.' = '.$self->query->param($field);
#		$dbg .= "<br />\n";
	}
#die $dbg;
	my $sql = 'select * from helpdesk where ';
	foreach my $c (@coldata){
		foreach my $k (keys %{$c}){
			if($c->{$k}->{'op'}){
				$sql .= $c->{$k}->{'op'}.' '.$k.$self->operator($c->{$k}->{'comparison'},$c->{$k}->{'value'});
			}
		}
	}

	$sql .= ';';
if(@coldata){
	die $sql;
	$dbg .= '<p>';
	while(my @d = $self->param('hddb')->selectrow_array($sql)){
		$dbg .= join(' ',@d);
		$dbg .= "<br>\n";
	}
}
	$self->param('template')->param('debug' => $dbg);
	return $self->param('template')->output;
}

sub operator{
	my $self = shift;
	my $cmp = shift;
	my $value = shift;
	if($cmp eq 'eq'){
		return ' = '.$self->param('hddb')->quote($value);
	} elsif($cmp eq 'like'){
		return ' like "%'.$self->param('hddb')->quote($value).'%"';
	} elsif($cmp eq 'between'){
		my ($start,$end) = split(/\|/,$value);
		return ' between '.$self->param('hddb')->quote($start).' and '.$self->param('hddb')->quote($end);
	}
}

sub default_sub{
	my $self = shift;

	my $scid = $self->school_from_ip();

	# Fill by this fieldmap, on this control field value
	$self->fill("edit-ticket.fieldmap","1");
	$self->school_selector('school_loop',$scid);
	$self->ticket_status_selector('status_loop');
	$self->priority_selector('priority_loop');
	$self->section_selector('section_loop',"1");

	$self->param('template')->param('self_url' => $self->query->url);

	my ($hwid, $swid, $model, $status, $school) = $self->param('hddb')->selectrow_array("select hardware_type, software, model, status, school  from inventory where ccps = 1");
	$self->fill("edit-ticket_inventory.fieldmap","1");
	$self->fill("edit-ticket_hardwaretype.fieldmap",$hwid);

}	



sub fill{
	my $self = shift;
	my $mapfile = shift;
	my $controlvalue = shift;

	my %fttp = $self->load_fieldmap($mapfile);
	my @columns = (values %{$fttp{'map'}});
	my $cols = join(', ',@columns);

	my $r = $self->param('hddb')->selectrow_hashref("select $cols from $fttp{'table'} where $fttp{'control'} = '$controlvalue';");

	my @can_get = $self->can_get($mapfile);

	foreach my $request (@can_get){
		if($request and $request !~ /loop/){
			$self->param('template')->param($request => $r->{$fttp{'map'}->{$request}});
		} else{
			# This is a loop, handle differently here.
			
		}	# Maybe handle all loops specially and first?
		
	}
	return @can_get;
}

sub can_get{
	my $self = shift;
	my $file = shift;
	my @requested_fields = $self->param('template')->query;
	my %map = $self->load_fieldmap($file);

	my @can_get; # What we actually can get, given this form submit and fieldmap
	foreach my $rf (@requested_fields){
		foreach my $mf (keys %{$map{'map'}}){
			if($mf eq $rf){
				push(@can_get,$mf);
			}
		}
	}
	return @can_get;
}

## 
## Internal functions
## 


sub load_fieldmap{
	my $self = shift;
	my $file = shift;
	open(FMAP,$file) or die $!;
	my @lines = <FMAP>;
	close(FMAP) or die $!;
	@lines = grep { /^[^#]/ } @lines;
	chomp @lines;

	my (%map,%f);
	foreach (@lines){

		# Get named params
		if($_ =~ /:/){
			my($n,$v) = split(/:/,$_);
			$f{$n} = $v;
		} else{ # Get table->field or field->table mappings
			my($k,$v) = split(/\t/,$_);
			$map{$k} = $v;
		}
	}
	$f{'map'} = \%map;
	return %f;
}

sub columns_of{
	my $self = shift;
	my $table = shift;
	my $h = $self->param('hddb')->prepare(
		qq(describe $table;),
	);
	$h->execute();
	my @columns;
	while(my @a = $h->fetchrow_array){
		push(@columns,shift(@a));
	}

	return @columns;
}

sub fill_by_barcode{
	my $self = shift;

	my $barcode = shift;
	my @fieldnames = $self->columns_of('helpdesk');

	my $h = $self->param('hddb')->prepare(
		qq(select * from helpdesk where barcode = ).$self->param('hddb')->quote($barcode).";",
	);
	$h->execute();
	my $data = $h->fetchrow_hashref;

	foreach my $item (@fieldnames){
#		if($field_to_template_param{$item}){
#			$self->param('template')->param($field_to_template_param{$item} => $data->{$item});
#		}
	}
}

sub generic_selector{
	my $self = shift;
	my $loop_var_name = shift;
	my @results = $self->generic_loop_results(@_);
	$self->param('template')->param($loop_var_name  => [@results]);
}

sub school_selector{
	my $self = shift;
	my $school_loop_var_name = shift;
	my @schools = $self->get_schools(@_);

	$self->param('template')->param($school_loop_var_name  => [@schools]);
	return 1;
}

sub ticket_status_selector{
	my $self = shift;
	my $loop_var_name = shift;
	my @entries = $self->get_ticket_statuses(@_);
	$self->param('template')->param($loop_var_name  => [@entries]);
	return 1;
}

sub priority_selector{
	my $self = shift;
	my $loop_var_name = shift;
	my @entries = $self->get_priorities(@_);
	$self->param('template')->param($loop_var_name  => [@entries]);
	return 1;
}

sub section_selector{
	my $self = shift;
	my $loop_var_name = shift;
	my @entries = $self->get_sections(@_);
	$self->param('template')->param($loop_var_name => [@entries]);
	return 1;
}



sub get_schools{
        my $self = shift;
        my $selected = shift;
        my $sortby = shift;

        if($sortby){
                $sortby = "order by $sortby";
        } else{
                $sortby = "order by name";
        }
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = -1;
        }
        my $sth = $self->param('hddb')->prepare("select scid,name from school $sortby;");
        $sth->execute();
	my @entries;
        while(my ($scid,$name) = $sth->fetchrow_array()){
		my %row;
		$row{'school_scid'} = $scid;
		$row{'school_name'} = $name;
		if($scid == $selected){
			$row{'selected'} = ' selected';
		} else{
			$row{'selected'} = '';
		}
		push(@entries,\%row);
	}
        return @entries;
}

## Making a loop map
#table:school
#order:name
#school_name	name
#school_scid	scid


sub get_ticket_statuses{
        my $self = shift;
        my $selected = shift;
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = 1;
        }
        my $sth = $self->param('hddb')->prepare("select tsid,name from ticket_status order by tsid;");
        $sth->execute();

	my @entries;
        while(my ($tsid,$status) = $sth->fetchrow_array()){
		my %row;
		$row{'status_tsid'} = $tsid;
		$row{'status_desc'} = $status;
		if($tsid == $selected){
			$row{'selected'} = ' selected';
		} else{
			$row{'selected'} = '';
		}
		push(@entries,\%row);
	}
        return @entries;
}

sub get_priorities{
        my $self = shift;
        my $selected = shift;
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = 3;
        }
        my $sth = $self->param('hddb')->prepare("select prid,description from priority order by severity;");
        $sth->execute();

	my @entries;
        while(my ($prid,$desc) = $sth->fetchrow_array()){
		my %row;
		$row{'priority_prid'} = $prid;
		$row{'priority_desc'} = $desc;
		if($prid == $selected){
			$row{'selected'} = ' selected';
		} else{
			$row{'selected'} = '';
		}
		push(@entries,\%row);
	}
        return @entries;
}

sub get_sections{
        my $self = shift;
        my $selected = shift;
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = 1;
        }
        my $sth = $self->param('hddb')->prepare("select sid,name from section order by sid;");
        $sth->execute();

	my @entries;
        while(my ($sid,$name) = $sth->fetchrow_array()){
		my %row;
		$row{'section_sid'} = $sid;
		$row{'section_label'} = $name;
		if($sid == $selected){
			$row{'selected'} = ' selected';
		} else{
			$row{'selected'} = '';
		}
		push(@entries,\%row);
	}
        return @entries;
}

1;
