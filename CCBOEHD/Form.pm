#!/usr/bin/perl

package CCBOEHD::Form;
use base qw(CCBOEHD::Base);

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
		'create' => 'create_mode',
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

sub no_cfg_specified{
	my $self = shift;
	return "Must specify cfg= and app= on the query string.";
}

sub new_mode{
	my $self = shift;
	$self->query->param('mode' => 'new');
	$self->populate_params('form.pl');

	$self->param('config')->{'current'}->{'template'} = $self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'new'}->{'template'};
	$self->load_template;

	$self->set_self_url;

	$self->fill_loops_createmode($self->param('form'));
#	$self->fill();

	# Using this here in this mode is largely untested but causes no errors.
	$self->form_fill($self->param('cgi'));

	return $self->param('template')->output();
}

sub create_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	my $debug;

	# Load requirements map into config
	$self->load_requirements($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'create'}->{'requirements'});
	my @err = $self->check_requirements();

	if(@err){
		# create_error mode
		$self->load_template($self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'create'}->{'error_template'});
		$self->set_self_url;
#die Data::Dumper::Dumper $self->param('config');;
		$self->param('template')->param('errors' => [@err]);

		$self->highlight_on_error(@err);

		$self->fill_loops_createmode($self->param('form'));

		$self->form_fill($self->param('cgi'));

	} else{
		# Insert the new row, capture the primary key

		my $pkey = ($self->next_primarykey_value());

		# Ugly hack!
		if($self->param('app') eq 'helpdesk'){
			$self->param('stash')->{'hardcoded'}->{'helpdesk'} = {
				'requested' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
				'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
				$self->param('select_html_field') => $pkey,
				'status' => $self->param('hddb')->selectrow_array("select min(tsid) from ticket_status;"),
			};
		} elsif($self->param('app') eq 'inventory'){
			# Set RAM, Speed, and HDD based on values in equipment for the equipment model we selected.
			# Effectively, must extract Model number from $self->('cgi'); and do an extra lookup.
			# Then, use results of that lookup to make a $hardcoded->{'inventory'} entry.
			my $eid = $self->param('cgi')->{'equipment_model'} || -1;
			my ($ram,$speed,$hdd,$sw,$os,$off,$cost,$type) = $self->param('hddb')->selectrow_array("select ram,speed,hdd,software,os,office,cost,type from equipment where eid = $eid;");
			$self->param('stash')->{'hardcoded'}->{'inventory'} = {
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
		} else{
			$self->param('stash')->{'hardcoded'}->{$self->param('form')->{'primarytable'}} = {
				$self->param('form')->{'where'}->{
					$self->param('form')->{'primarytable'}
				}->{'db_field'}
				 => 
				$self->param('cgi')->{
					$self->param('form')->{'where'}->{
						$self->param('form')->{'primarytable'}
					}->{'db_field'}
				} || $pkey,
			};
		}
		# Use the "new" mode form for create mode SQL creation. Necessary! Hope it doesn't break things...
		my @statements = $self->create_insert_statements2($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'new'}->{'form'},$self->param('cgi'));
#die Data::Dumper::Dumper @statements;
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
			$self->query->param(-name => 'mode', -value => 'view');
			return $self->view_mode();
#			$self->load_template($self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'create'}->{'template'});
#			$self->fill($pkey,$self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{'helpdesk'}->{'form.pl'}->{'create'}->{'form'});
		}
	}

	$self->param('template')->param('debug' => $debug);
	return $self->param('template')->output();
}


sub edit_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	$self->form_file_sanity_check;

	$self->load_template($self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'edit'}->{'template'});

	$self->set_self_url;

	$self->view_or_edit_mode;

	return $self->param('template')->output();
}
sub view_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	$self->load_template($self->param('config')->{'template_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'view'}->{'template'});

	$self->set_self_url;

	$self->view_or_edit_mode;

	return $self->param('template')->output();
}

sub view_or_edit_mode{
	my $self = shift;

	if(defined($self->param('cgi')->{$self->param('select_html_field')})){
		my $exists = $self->fill($self->param('cgi')->{$self->param('select_html_field')});
		if($exists == 0){
			$self->new_mode;
		}
	} else{
		# An error page would be appropriate
		croak "Something wicked happened! $!!. This means you forgot to give me a primary key field.";
	}
}



sub update_mode{
	my $self = shift;
	$self->populate_params('form.pl');

	$self->load_template($self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'update'}->{'template'});
	$self->set_self_url;

	# An ugly hack! I see no clean way to avoid it at the moment
	if($self->param('cgi')->{'app'} eq 'helpdesk'){
		$self->param('stash')->{'hardcoded'}->{'helpdesk'} = {
			'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
		};
	} elsif($self->param('cgi')->{'app'} eq 'inventory'){
		$self->param('stash')->{'hardcoded'}->{'inventory'} = {
			'updated' => $self->param('hddb')->selectrow_array("select from_unixtime(".(time).");"),
		};
	}

	$self->create_update_statements;

	# Catch the return code so we can check the status of what jsut happened.
	my (@rc,@err,$rowtot);
	foreach my $sql (@{$self->param('stash')->{'updates'}}){
		my $rc = $self->param('hddb')->do($sql);
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

	$self->fill($self->param('cgi')->{$self->param('select_html_field')},$self->param('config')->{'config_dir'}.'/'.
	$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'update'}->{'form'});

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
sub create_insert_statements2{
	my $self = shift;
	my $formfile = shift;
	my $formsubmit = shift;

	my %special_inserts = %{$self->param('stash')->{'hardcoded'}};

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
	my %FORM = $self->form_to_variables(); # Because THAT's not confusing.

	# Fill loop H::T vars
	my %loopsql = $self->get_loop_sqls($form);
	my @loop_objects = $self->get_loop_objects($form);
	foreach my $lobj (@loop_objects){

#		# Special case (how I loathe thee!) to select the current school's IP (if determinable)
#		if($lobj->{'value_from_db_field'} eq 'School'){
#			$lobj->{'default_selected'} = $self->school_from_ip() || $lobj->{'default_selected'};
#		}
# This is now handled via fill_from_function in the map file which references school_from_ip where appropriate

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
		# New primary key value was specified on command line
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
sub create_update_statements{
	my $self = shift;

	# Grab CGI form submission
	my %cgi = %{$self->param('cgi')};

	# Grab the .form file description of this submission
	my $form = $self->param('form');

#	the old way:
#	my %special_updates = @_;

	# the MVC way:
	# Update fields not necessarily mentioned in CGI
	# It's bad to rely on how they happen to be stored, but I do many bad things.
	my %special_updates = %{$self->param('stash')->{'hardcoded'}};

	my @updates;
	foreach my $t (keys %{$form->{'fields'}}){
		my $statement = 'update '.$t.' set ';
		my @sets;
		foreach my $f (@{$form->{'fields'}->{$t}}){
			if(defined $f->{'html_field'} && defined $f->{'db_field'}){

				# Perform transformations on special field types.
				if(defined $f->{'field_type'}){

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

	$self->param('stash')->{'updates'} = \@updates;
}

#
# Common or generic functions
#





sub remove_dups{
	my $self = shift;
	my @in = @_;
	my %saw;
	undef %saw;
        @saw{@in} = ();
        my @out = sort keys %saw;  # remove sort if undesired
	return @out;
}

# This is a mixed Controller/View function. It parses CGI, which is Control, then fills template variables.
# Better system: Parse CGI into stash and also load DB into stash. Then have a single function which populates
# template from stash. Much cleaner!
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
				$self->throw_error("Config error: Form field $k has no matching ht_field.");
			}
		}
	}
}


# This is a definite View function. It takes data (from @err instead of stash, but still) and modifies the output.
# Actually, in TT this would all be done in the template.
sub highlight_on_error{
	my $self = shift;

	my @errs = @_;

#	my @vars = grep { /^error_/ } $self->param('template')->query;
#die Data::Dumper::Dumper @errs;
	foreach my $e (@errs){
		if($self->param('template')->query(name => 'error_'.$e->{'html'})){
			$self->param('template')->param('error_'.$e->{'html'} => ' class="highlightonerror" ');
			delete $e->{'html'};
		}
	}
}

sub field_as_from_field_html{
	my $self = shift;
	my $f = shift;
	my $match = shift;
#die Data::Dumper::Dumper $f;
	foreach my $t (keys %{$f->{'fields'}}){
		foreach my $field (@{$f->{'fields'}->{$t}}){
			if($field->{'html_field'} eq $match){
				return $field->{'as'};
			}
		}
	}

	return undef;
}
sub field_ht_from_field_html{
	my $self = shift;
	my $match = shift;
	my $f = $self->param('form');

	return undef unless defined $match; # must specify requested html field

#die Data::Dumper::Dumper $f;
	foreach my $t (keys %{$f->{'fields'}}){
		foreach my $field (@{$f->{'fields'}->{$t}}){
			# Sometimes we don't specify an HTML field because we don't want to pull this value 
			# from a form input (e.g., the Primary Key in a auto_increment table
			if(defined $field->{'html_field'} && $field->{'html_field'} eq $match){
#die  Data::Dumper::Dumper $field if $match eq 'troubleshoot';
				return $field->{'ht_field'};
			}
		}
	}

	return undef;
}

sub check_requirements{
	my $self = shift;
	my $reqmap = shift;
	my @errors;
	my %form = %{$self->param('cgi')};
	# We *always* want new mode's form on error.
	my $f = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{'form.pl'}->{'new'}->{'form'});
	my %stipulations = %{$self->param('config')->{'stipulations'}};

	if(ref %stipulations){
		# is a reference. Should be a hash
		# give a friendly warning (or, for now, an unfriendly warning)
		die "Stipulations hash was a reference!";
	}

	foreach my $s (keys %stipulations){
		if($stipulations{$s} =~ /required/){
			if(!defined($form{$s}) || $form{$s} eq ''){ #
				my %tmp;
				# For when I forget later:
				# $tmp{'html'} is for the HTML form field name, which combined with the prefix 
				# error_ gives you the HTML::Template variable name into which to insert the 
				# "This is an error" CSS.
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must not be empty";
				unshift(@errors,\%tmp); # And make 'em appear in the original order
			}
		}
		if($stipulations{$s} =~ /onlynumeric/){
			if($form{$s} !~ /\d+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must be a number";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /alphabetic/){
			if($form{$s} !~ /(\w|\s)+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must consist of letters only";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /alphanumeric/){
			if($form{$s} !~ /(\w|\d|\s)+/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must contain no punctuation";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /morethantwo/){
			if(length($form{$s}) < 3){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must be more than two characters";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /morethan(\d+)/){
			my $n = $1;
			if(length($form{$s}) <= $n){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must be more than $n character".($n==1?'':'s');
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /isemail/){
			if($form{$s} !~ /.*\@.*\..{2,5}/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "is not a valid email address";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /ismac/){
			if($form{$s} !~ /^([abcdefABCDEF0123456789]{2}[ -:]?){6}$/ and $form{$s} ne ''){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "is not a valid MAC address";
				unshift(@errors,\%tmp);
			}
		}
		if($stipulations{$s} =~ /nonzero/){
			if($form{$s} == 0){
				my %tmp;
				$tmp{'html'} = $s;
				$tmp{'name'} = $self->field_as_from_field_html($f,$s) || $s;
				$tmp{'msg'} = "must not be zero";
				unshift(@errors,\%tmp);
			}
		}

	}

	unless($self->param('store')){
		$self->param('store', {'current' => {}});
	}
	$self->param('store')->{'current'}->{'errors'} = [@errors];
	return @errors;
}


sub form_file_sanity_check{
	my $self = shift;

	my $file = $self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('app')}->{'form.pl'}->{$self->param('mode')}->{'form'};
	my $form = $self->param('form');

	# May not have duplicate As parameters.
	my @as;
	foreach my $t (keys %{$form->{'fields'}} ){
		my $i = 0;
		foreach my $f ( @{$form->{'fields'}->{$t}} ){
			if($self->match_any(@as,$f->{'as'})){
				# Throw as collision error
				die "$file: fields: $t: $f->{'db_field'}: field $i: As collision on $f->{'as'}.\n";
			} else{
				push(@as,$f->{'as'});
			}
			$i++
		}
	}
	# just the one check for now.

}



sub load_requirements{
	my $self = shift;
	my $file = shift;
	my $r = YAML::LoadFile($file);
	$self->param('config')->{'stipulations'} = $r;
#	croak Data::Dumper::Dumper $r;
	return %{$r}; # Legacy
}

#---------------new stuff----------------#



1;
