#!/usr/bin/perl

package CCBOEHD::Inventory;
use base qw(CCBOEHD::Form);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;
use YAML;
use Date::Manip qw/UnixDate/;

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
		'create' => 'catch_create_errors',
		'edit' => 'edit_mode',
		'view' => 'view_mode',
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
	$self->query->param('mode' => 'new');
	$self->populate_params('form.pl');
	$self->load_template($self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'new'}->{'template'});

	$self->set_self_url;

	$self->fill_loops_createmode($self->param('form'));

	# Using this here in this mode is largely untested but causes no errors.
	$self->form_fill($self->param('cgi'));

	return $self->param('template')->output();
}


sub catch_create_errors{
	my $self = shift;
	$self->query->param('app' => 'inventory');
	$self->populate_params('form.pl');

	my @err = $self->check_requirements();

	if(@err){
		# create_error mode
		$self->load_template($self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'create'}->{'error_template'});
		$self->set_self_url;
#die Data::Dumper::Dumper $self->param('config');;
		$self->param('template')->param('errors' => [@err]);

		$self->highlight_on_error(@err);

		$self->fill_loops_createmode($self->param('form'));

		$self->form_fill($self->param('cgi'));

		return $self->param('template')->output();
	} else{
		return $self->create_mode;
	}
}

sub create_mode{
	my $self = shift;
	$self->query->param('app' => 'inventory');
	$self->populate_params('form.pl');


	# Insert the new row, capture the primary key

	my $pkey = ($self->next_primarykey_value());

	my %flds;
	# Set RAM, Speed, and HDD based on values in equipment for the equipment model we selected.
	# Effectively, must extract Model number from $self->('cgi'); and do an extra lookup.
	# Then, use results of that lookup to make a $flds{'inventory'} entry.
	my $eid = $self->param('cgi')->{'equipment_model'} || -1;
	my ($ram,$speed,$hdd,$sw,$os,$off,$cost,$type) = $self->param('hddb')->selectrow_array("select ram,speed,hdd,software,os,office,cost,type from equipment where eid = $eid;");

	$flds{$self->param('form')->{'primarytable'}} = {
		# puts in the field name from where: inventory: db_field
		$self->param('form')->{'where'}->{
			$self->param('form')->{'primarytable'}
		}->{'db_field'}
		 => 
		# looks in CGI query str for a key called where: inventory: db_field: and inserts its value
		$self->param('cgi')->{
			$self->param('form')->{'where'}->{
				$self->param('form')->{'primarytable'}
			}->{'db_field'}
		} || $pkey,
	};
	$flds{'inventory'} = {
		$flds{'inventory'},
		'inventory.ram' => $ram,
		'inventory.speed' => $speed,
		'inventory.hdd' => $hdd,
		'inventory.software' => $sw,
		'inventory.os' => $os,
		'inventory.office' => $off,
		'inventory.cost' => $cost,
		'inventory.hardware_type' => $type,
		'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
	};

	# Use the "new" mode form for create mode SQL creation. Necessary! Hope it doesn't break things...
	my @statements = $self->create_insert_statements2($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'new'}->{'form'},$self->param('cgi'),%flds);
	my @error;
	foreach my $st (@statements){
		my $rc = $self->param('hddb')->do($st);
		if(!defined($rc)){
			my $e = $self->param('hddb')->errstr;
			push(@error,{'error' => $e});
		}
	}
	if(@error){
		$self->load_template($self->param('config')->{'config_dir'}.'/'.$$self->param('config')->{'pnd'}->{'helpdesk'}->{'form.pl'}->{'create'}->{'error_template'});
		$self->param('template')->param('sql_error',[@error]);
		$self->form_fill($self->param('cgi'));
		$self->fill_loops_createmode($self->param('form'));
	} else{
		$self->load_template($self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'create'}->{'template'});
		$self->fill($pkey,$self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'helpdesk'}->{'form.pl'}->{'create'}->{'form'});
	}

	return $self->param('template')->output();
}


sub edit_mode{
	my $self = shift;
	$self->query->param('app' => 'inventory');
	$self->populate_params('form.pl');

#	my %form = $self->form_to_variables;
#	$self->param('cgi', \%form);
#	my $edit_mode_form = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'edit'}->{'form'});
#	$self->param('form', $edit_mode_form);

	$self->load_template($self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'edit'}->{'template'});

	$self->set_self_url;
#die Data::Dumper::Dumper $self->param('cgi');
#die Data::Dumper::Dumper $self->param('select_html_field');

	if(defined($self->param('cgi')->{$self->param('select_html_field')})){
		my $exists = $self->fill($self->param('cgi')->{$self->param('select_html_field')});
		if($exists == 0){
			$self->new_mode;
		}
	} else{
		# An error page would be appropriate
		croak "Something wicked happened! $!!. This means you forgot to give me a primary key field.";
	}
	return $self->param('template')->output();
}

sub view_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	$self->load_template($self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'view'}->{'template'});
	$self->set_self_url;

	if(defined($self->param('cgi')->{$self->param('select_html_field')})){
		my $exists = $self->fill($self->param('cgi')->{$self->param('select_html_field')});
		if($exists == 0){
			$self->new_mode;
		}
	} else{
		# An error page would be appropriate here
		# Print out a temporary page that redirects to somewhere. New mode? 
		croak "Something wicked happened! $!!. This means you forgot to give me a primary key field.";
	}

	return $self->param('template')->output();
}

sub update_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	$self->load_template($self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'update'}->{'template'});
	$self->set_self_url;

	# An ugly hack! I see no clean way to avoid it at the moment. Now I can. Use MySQL Datestamp field.
	my %flds;
	$flds{'inventory'} = {
		'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
	};

	my @updates = $self->create_update_statements(%flds);
#die $updates[0];
	# Catch the return code so we can check the status of what jsut happened.
	my (@rc,@err,$rowtot);
#die Data::Dumper::Dumper @updates;
	foreach my $upd (@updates){
		my $rc = $self->param('hddb')->do($upd);
		if(!defined($rc)){
			my $e = $self->param('hddb')->errstr;;
			push(@err,{'error' => $e});
		} else{
			$rowtot += $rc;
		}
	}
#	$err[0] = {'error'=>'foo is bad!'}; # Force an error condition for testing.
	if(@err){
		$self->param('template')->param('sql_error',[@err]);
	} elsif($rowtot){
		$self->param('template')->param('sql_success',$rowtot);
	}

#	$self->param('template')->param('debug' => $debug);
#die $self->param('select_html_field');
	$self->fill($self->param('cgi')->{$self->param('select_html_field')},$self->param('config')->{'config_dir'}.'/'.
	$self->param('config')->{'pnd'}->{'inventory'}->{'form.pl'}->{'update'}->{'form'});

	return $self->param('template')->output();
}



## ###################
## Internal functions
## ###################

#
# New mode functions
#

#
# Create mode functions
#
sub create_insert_statements2{
	my $self = shift;
	my $formfile = shift;
	my $formsubmit = shift;
	my %special_inserts = @_;

	my %form = %{$formsubmit};
	my $form2 = YAML::LoadFile($formfile);

	my @inserts;
	foreach my $t (keys %{$form2->{'fields'}}){
		my $statement = 'insert into '.$t.' ';
		my (@fieldlist,@valuelist);
		foreach my $f (@{$form2->{'fields'}->{$t}}){
			if(defined $f->{'html_field'} && defined $f->{'db_field'}){
				if(lc($f->{'field_type'}) eq 'date'){
					my $unixtime = (UnixDate($form{$f->{'html_field'}},"%s")||0);
					if($unixtime){
						$form{$f->{'html_field'}} = $self->param('hddb')->selectrow_array("select from_unixtime(".($unixtime).");");
					} else{
						$form{$f->{'html_field'}} = 0;
					}
				}
				push(@fieldlist,$f->{'db_field'});
				push(@valuelist,$form{$f->{'html_field'}});
			}
		}
		if($special_inserts{$t}){
			foreach my $f (keys %{$special_inserts{$t}}){
				push(@fieldlist,$f);
				push(@valuelist,$special_inserts{$t}->{$f});
			}
		}

		if(@fieldlist && @valuelist){
			$statement .= '('.join(', ',@fieldlist).') values ('.join(', ',(map {$self->param('hddb')->quote($_)} @valuelist)).');';
			push(@inserts,$statement);
		}
	}
	return @inserts;
}

sub fill_loops_createmode{
	my $self = shift;
	my $form = shift;
	my %FORM = $self->form_to_variables();

	# Fill loop H::T vars
	my %loopsql = $self->get_loop_sqls($form);
	my @loop_objects = $self->get_loop_objects($form);
	foreach my $lobj (@loop_objects){

		# Special case (how I loathe thee!) to select the current school's IP (if determinable)
		if($lobj->{'value_from_db_field'} eq 'School'){
			$lobj->{'default_selected'} = $self->school_from_ip() || $lobj->{'default_selected'};
		}

		# Form, SQL, Loopname, Match value
		$self->insert_loop_into_template(
			$form,				# for object
			$loopsql{$lobj->{'loopname'}},	# sql for this loop
			$lobj->{'loopname'},		# loop name

			# Select the value the user selected, or use the default if user selection not supplied
			$FORM{$lobj->{'value_from_html_field'}} || $lobj->{'default_selected'}
		);
	}
	return;
}

sub next_primarykey_value{
	my $self = shift;
	my %form = $self->form_to_variables;
	my $y = $self->param('form');
	if(defined($self->param('cgi')->{$y->{'where'}->{$y->{'primarytable'}}->{'db_field'}})){
		# Primary key value was specified on query string as primarykeyname=value
		return $self->param('cgi')->{$y->{'where'}->{$y->{'primarytable'}}->{'db_field'}};
	} else{
		# Pick a new one
		return $self->param('hddb')->selectrow_array("select max(".$self->param('select_db_field').") from ".$y->{'primarytable'}.";") + 1; 
	}
}

#
# Edit mode functions
#

#
# Update mode functions
#


# Using the associations laid out in a .form file, transform the CGI POST submission of form data into SQL statement(s).
sub create_update_statements_from_cgi_submit{
	my $self = shift;

	# Grab CGI form submission
	my %cgi = %{$self->param('cgi')};

	# Grab the .form file description of this submission
	my $form = $self->param('form');

	# Update fields not necessarily mentioned in CGI
	my %special_updates = @_;

	my @updates;
	foreach my $t (keys %{$form->{'fields'}}){
		my $statement = 'update '.$t.' set ';
		my @sets;
		foreach my $f (@{$form->{'fields'}->{$t}}){
			if(defined $f->{'html_field'} && defined $f->{'db_field'}){

				# Perform transformations on special field types.
				if(defined $f->{'field_type'}{

					# Date fields should be preprocessed by Date::Manip
					if($f->{'field_type'} eq 'date'){
						my $unixtime = (UnixDate($cgi{$f->{'html_field'}},"%s")||0);
						if($unixtime){
							$cgi{$f->{'html_field'}} = $self->param('hddb')->selectrow_array("select from_unixtime(".($unixtime).");");
						} else{
							$cgi{$f->{'html_field'}} = 0; 
						}
					}
				}
				push(@sets,$f->{'db_field'}.' = '.$self->param('hddb')->quote($cgi{$f->{'html_field'}}));
			}
		}

		# Include updates to explicitly mentioned fields and values (not from CGI)
		if($special_updates{$t}){
			foreach my $f (keys %{$special_updates{$t}}){
				push(@sets,$f.' = '.$self->param('hddb')->quote($special_updates{$t}->{$f}));
			}
		}

		if(@sets){
			my $val = $self->param('hddb')->quote($cgi{$form->{'where'}->{$t}->{'html_field'}});
			my $pat = $self->operator_txt_to_pattern($form->{'where'}->{$t}->{'comparison'});
			$pat =~ s/\*/$val/;
			my $where = 'where '.$form->{'where'}->{$t}->{'db_field'}.' '.($self->operator_txt_to_operator($form->{'where'}->{$t}->{'comparison'})).' '.$val;

			$statement .= join(', ', @sets).' '.$where.';';
			push(@updates,$statement);
		} else{
			# Found no update sets. This is perfectly okay. No cause for panic.
			# All it means is that no data was submitted that makes sence with this .form file
		}
	}
	return @updates;
}

#
# Common or generic functions
#






sub form_fill{
	my $self = shift;
	my $cgi = shift;

	# For now we assume that the first hit is correct.
	foreach my $k (keys %{$cgi}){
		my $htf = $self->field_ht_from_field_html($k);
#		$htf = $k unless $htf;
#		die $htf if $k eq 'app';
		if($htf){
			if($self->param('template')->query(name => $htf)){
				$self->param('template')->param($htf => $cgi->{$k})
			} else{
				$self->throw_error("Config error: Form field $k has no matching template field.");
			}
		}
	}
}




1;
