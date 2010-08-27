#!/usr/bin/perl

package CCBOEHD::Ticket;
use base qw(CCBOEHD::Base);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;
use YAML;

##
## Overrides
##

sub setup
{
	my $self = shift;

	$self->start_mode('new');
	$self->mode_param('mode');
	$self->run_modes(
		'new' => 'new_mode',
		'create' => 'create_mode',
		'edit' => 'edit_mode',
		'update' => 'update_mode',
	);
	$self->load_config;
	$self->db_connect;
}

## 
## Interface functions
## 

sub new_mode{
	my $self = shift;
	my %form = $self->form_to_variables();
	my $app = $form{'app'}; # app=helpdesk, use in template load below
	$self->load_template($self->param('config')->{'pnd'}->{'helpdesk'}->{'ticket.pl'}->{'new'}->{'template'});

	$self->param('template')->param('self_url' => $self->query->url);

	my $scid = $self->school_from_ip();

	$self->generic_selector('school_loop','schools.loopmap',$scid || 0);
	$self->generic_selector('priority_loop','priority.loopmap');
	$self->generic_selector('section_loop','sections.loopmap');

	return $self->param('template')->output();
}

sub create_mode{
	my $self = shift;

	my $debug;

	my %form = $self->form_to_variables();
	my @err = $self->check_requirements($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'reqmap'},%form);

	if(@err){
		$self->load_template($self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'error_template'});

		$self->param('template')->param('errors' => [@err]);

		$self->highlight_on_error(@err);

		$self->form_fill(%form);

		$self->generic_selector('school_loop','schools.loopmap',$form{'school'} || 1);
		$self->generic_selector('priority_loop','priority.loopmap',$form{'priority'});
		$self->generic_selector('section_loop','sections.loopmap',$form{'section'});
	} else{
		# Insert the ticket, capture the ticket number

		my $ticket = ($self->next_ticket_number())+1;

		my %flds;
		$flds{'helpdesk'} = { 
			'requested' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
			'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
			'ticket' => $ticket,
			'status' => $self->param('hddb')->selectrow_array("select min(tsid) from ticket_status;"),
		};

		my @statements =  $self->create_insert_statements($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'smap'},\%form,%flds);

		my @error;
		foreach my $st (@statements){
			my $rc = $self->param('hddb')->do($st);
			if(!defined($rc)){
				my $e = $self->param('hddb')->errstr;
				push(@error,{'error' => $e});
			}
		}
		if(@error){
			$self->load_template($self->param('config')->{'config_dir'}.'/'.$$self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'error_template'});
			$self->param('template')->param('sql_error',[@error]);
			$self->form_fill(%form);
			$self->generic_selector('school_loop','schools.loopmap',$form{'school'} || 1);
			$self->generic_selector('priority_loop','priority.loopmap');
			$self->generic_selector('section_loop','sections.loopmap');
		} else{
			$self->load_template($self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'template'});
 			my %nfm = $self->load_nfm($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'ticket.pl'}->{'create'}->{'nfm'});
			$self->fill($ticket,%nfm);
		}
	}

	$self->param('template')->param('debug' => $debug);

	return $self->param('template')->output();
}


sub edit_mode{
	my $self = shift;

	$self->load_template($self->param('config')->{'pnd'}->{'ticket.pl'}->{'edit'}->{'template'});

	my %form = $self->form_to_variables();
	$self->param('template')->param('self_url' => $self->query->url);

	if(defined($form{'ticket'})){
		my %nfm = $self->load_nfm($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'ticket.pl'}->{'edit'}->{'nfm'});
		$self->fill($form{'ticket'},%nfm);
	} else{
		# An error page would be appropriate
		die "Something wicked happened! $!!. This means you forgot to give me a ticket field.";
	}

	return $self->param('template')->output();
}

sub update_mode{
	my $self = shift;

	$self->load_template($self->param('config')->{'pnd'}->{'ticket.pl'}->{'update'}->{'template'});
	$self->param('template')->param('self_url' => $self->query->url);
	my %form = $self->form_to_variables();

	my %flds;
	$flds{'helpdesk'} = { 
		'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
	};



	my @updates = $self->create_update_statements($self->param('config')->{'pnd'}->{'ticket.pl'}->{'update'}->{'smap'},\%form,%flds);

	# Catch the return code so we can check the status of what jsut happened.
	my (@rc,@err,$rowtot);
	foreach my $upd (@updates){
		my $rc = $self->param('hddb')->do($upd);
		if(!defined($rc)){
			my $e = $self->param('hddb')->errstr;;
			push(@err,{'error' => $e});
		} else{
			$rowtot += $rc;
		}
	}
#	$err[0] = {'error'=>'foo is bad!'}; # Force an error condition. Fot testing.
	if(@err){
		$self->param('template')->param('sql_error',[@err]);
	} elsif($rowtot){
		$self->param('template')->param('sql_success',$rowtot);
	}

#	$self->param('template')->param('debug' => $debug);

	$self->fill($form{'ticket'}, $self->load_nfm($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'ticket.pl'}->{'update'}->{'nfm'}));

	return $self->param('template')->output();
}



## 
## Internal functions
## 

#
# New mode functions
#

#
# Create mode functions
#

sub create_insert_statements{
	my $self = shift;
	my $smap = shift;

	my $ref = YAML::LoadFile($smap);
	my $form = shift;
	my %special_inserts = @_;
	my @inserts;
	my @tables = keys %{$ref};

	foreach my $t (@tables){
		my %fields;
		my $statement = 'insert into '.$t.' ';
		foreach my $k (keys %{$ref->{$t}}){
			if(defined($form->{$k})){
				$fields{$ref->{$t}->{$k}} = $form->{$k};
			}
		}
		my @fieldlist;
		my @valuelist;
		foreach my $f (keys %fields){
			push(@fieldlist,$f);
			push(@valuelist,$fields{$f});
		}

		if($special_inserts{$t}){
			foreach my $f (keys %{$special_inserts{$t}}){
				push(@fieldlist,$f);
				push(@valuelist,$special_inserts{$t}->{$f});
			}
		}

		$statement .= '('.join(',',@fieldlist).') values ('.join(',',(map {$self->param('hddb')->quote($_)} @valuelist)).');';
		push(@inserts,$statement);
	}

	return @inserts;
}


sub next_ticket_number{
	my $self = shift;
	return $self->param('hddb')->selectrow_array("select max(ticket) from helpdesk;");
}

#
# Edit mode functions
#

#
# Update mode functions
#

sub create_update_statements{
	my $self = shift;
	my $yaml_file = shift;

	my $ref = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$yaml_file);
	my $form = shift;
	my %special_updates = @_;
	my @updates;
	my @tables = keys %{$ref};

	foreach my $t (@tables){
		my %fields;
		my $statement = 'update '.$t.' set ';
		my @sets;
		foreach my $k (keys %{$ref->{$t}->{'map'}}){
			if(defined($form->{$k})){
				push(@sets,$ref->{$t}->{'map'}->{$k}.' = '.$self->param('hddb')->quote($form->{$k}));
			}
		}

		if($special_updates{$t}){
			foreach my $f (keys %{$special_updates{$t}}){
				$form->{$f} = $special_updates{$t}->{$f};
				push(@sets,$f.' = '.$self->param('hddb')->quote($special_updates{$t}->{$f}));
			}
		}
		# Change the 'where = %s' into where = ACTUAL_TICKET_NUMBER
		$ref->{$t}->{'where'} = sprintf($ref->{$t}->{'where'},$self->param('hddb')->quote($form->{$ref->{$t}->{'field'}}));

		$statement .= join(', ',@sets).' where '.$ref->{$t}->{'where'}.';';
#		my $m = grep { /\%/g } $statement;
#die $statement;
#		$statement = sprintf($statement,$self->param('hddb')->quote($form->{$ref->{$t}->{'field'}}));
#die $form->{$ref->{$t}->{'field'}};
#die $statement;
		push(@updates,$statement);
	}

	return @updates;
}

#
# Common or generic functions
#

sub fill{
	my $self = shift;
	my $match = shift;
	my %nfm = @_;
	$self->fill_loops($match,%nfm);
	my $sql = $self->nfm_to_sql($match,%nfm);
	chomp($sql);
	chomp($sql);
	chomp($sql);
	chomp($sql);
	chomp($sql);
	my $result = $self->param('hddb')->selectrow_hashref($sql);
	my $dbg = '';

	foreach my $label (keys %{$result}){
		foreach my $mapping (values(%{$nfm{'map'}})){
			$mapping->{'label'} =~ s/"//g;
			if($mapping->{'label'} eq $label){
				$self->param('template')->param($mapping->{'field'},$result->{$label});
				last;
			}
		}
	}

	return $dbg;
}

sub fill_loops{
	my $self = shift;
	my $match = shift;
	my %nfm = @_;
	my (%lmap,@loop_tables,@loop_selectfrom);
	foreach my $l (keys %nfm){
		if($l =~ /loop/){
			my ($templatename,$filename,$fieldname_tablename) = split(/;/,$nfm{$l});
			my($fieldname,$tablename) =  split(/,/,$fieldname_tablename);
			push(@loop_tables,$tablename);
			$fieldname = $fieldname.' as '.$templatename;
			$lmap{$templatename} = $filename;
			push(@loop_selectfrom,$fieldname);
		}
	}
	@loop_tables = $self->remove_dups(@loop_tables);
	if(@loop_tables){
		my $sql = 'select '.join(',',@loop_selectfrom).' from '.join(',',@loop_tables).' where '.
			   $nfm{'where_field'}.' = '.($self->param('hddb')->quote($match)).';'; 
		my $result = $self->param('hddb')->selectrow_hashref($sql);
		foreach my $tmpl (keys %{$result}){
			# tmpl = template variable name
			# lmap{tmpl} = what we got from the nfm as the filename
			# result->{tmpl} = the value of the field in the db
			$self->generic_selector($tmpl,$lmap{$tmpl},$result->{$tmpl});
		}
	}
}

sub remove_dups{
	my $self = shift;
	my @in = @_;
	my %saw;
	undef %saw;
        @saw{@in} = ();
        my @out = sort keys %saw;  # remove sort if undesired
	return @out;
}

sub form_fill{
	my $self = shift;
	my %form = @_;

	foreach my $k (keys %form){
		if($self->param('template')->query(name => $k)){
			$self->param('template')->param($k => $form{$k})
		}
	}
}

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

sub generic_selector{
	my $self = shift;
	my $loop_var_name = shift;
	my @entries = $self->get_generic_selector(@_);
	return $self->param('template')->param($loop_var_name => [@entries]);
}

sub get_generic_selector{
	my $self = shift;
	my $file = shift;
        my $selected = shift;
        my $sortby = shift;

	my %map = $self->load_fieldmap($self->param('config')->{'config_dir'}.'/'.$file);

        if($sortby){
                $sortby = "order by $sortby";
        } else{
                $sortby = 'order by '.$map{'sort'};
        }
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = $map{'selected'};
        }

	my $sth = $self->param('hddb')->prepare("select ".$map{'fields'}." from ".$map{'table'}." $sortby;");
        $sth->execute();
	my @entries;

        while(my $hrrow = $sth->fetchrow_hashref()){
		my %row;
		foreach my $k (keys %{$map{'map'}}){
			$row{$k} = $hrrow->{$map{'map'}->{$k}};
		}
		if($hrrow->{$map{'select'}} eq "$selected"){
			$row{'selected'} = ' selected';
		} else{
			$row{'selected'} = '';
		}
		push(@entries,\%row);
	}
        return @entries;
}

sub highlight_on_error{
	my $self = shift;

	my @errs = @_;

#	my @vars = grep { /^error_/ } $self->param('template')->query;

	foreach my $e (@errs){
		if($self->param('template')->query(name => 'error_'.$e->{'name'})){
			$self->param('template')->param('error_'.$e->{'name'} => ' class="highlightonerror" ');
		}
	}
}

sub check_requirements{
	my $self = shift;
	my $reqmap = shift;
	my @errors;
	my %form = @_;
	my %stipulations = $self->load_requirements($reqmap);

	foreach my $s (keys %stipulations){
		if($stipulations{$s} =~ /required/){
			if(!defined($form{$s}) || $form{$s} eq ''){ #
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must not be empty";
				unshift(@errors,\%tmp); # And make 'em appear in the original order
			}
		}
		if($stipulations{$s} =~ /onlynumeric/){
			if($form{$s} !~ /\d+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must be a number";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /alphabetic/){
			if($form{$s} !~ /(\w|\s)+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must consist of letters only";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /alphanumeric/){
			if($form{$s} !~ /(\w|\d|\s)+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must contain no punctuation";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /morethantwo/){
			if(length($form{$s}) < 3){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must be more than two characters";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /morethan(\d+)/){
			my $n = $1;
			if(length($form{$s}) <= $n){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "must be more than $n character".($n==1?'':'s');
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /isemail/){
			if($form{$s} !~ /.*\@.*\..{2,5}/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'name'} = $s;
				$tmp{'msg'} = "is not a valid email address";
				unshift(@errors,\%tmp);
			}
		}


	}
	return @errors;
}


sub load_requirements{
	my $self = shift;
	my $file = shift;

	open(FH,$file) or die "unable to open $file: $!";
	my @lines = <FH>;
	close(FH) or die $!;
	my %map;
	foreach my $l (@lines){
		chomp($l);
		next if $l =~ /^#/;
		$l =~ s/#.*$//;
		my($field,$requirement) = split(/:/,$l);
		$map{$field} = $requirement;
	}
	return %map;
}

#sub can_get{
#	my $self = shift;
#	my $file = shift;
#	my @requested_fields = $self->param('template')->query;
#	my %map = $self->load_fieldmap($file);
#
#	my @can_get; # What we actually can get, given this form submit and fieldmap
#	foreach my $rf (@requested_fields){
#		foreach my $mf (keys %{$map{'map'}}){
#			if($mf eq $rf){
#				push(@can_get,$mf);
#			}
#		}
#	}
#	return @can_get;
#}

#sub columns_of{
#	my $self = shift;
#	my $table = shift;
#	my $h = $self->param('hddb')->prepare(
#		qq(describe $table;),
#	);
#	$h->execute();
#	my @columns;
#	while(my @a = $h->fetchrow_array){
#		push(@columns,shift(@a));
#	}
#
#	return @columns;
#}

1;
