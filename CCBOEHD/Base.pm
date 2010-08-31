#!/usr/bin/perl

package CCBOEHD::Base;
use base qw(CGI::Application);

use strict;
use warnings;

use DBI;
use HTML::Entities;
use HTML::Template;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Carp;
use Data::Dumper;

sub cgiapp_init{
	my $self = shift;

	$self->load_config();

	$self->db_connect();

	# Setup mandatory variables
	
	if($self->school_from_ip() == 0){
		$self->param('login' => 1);
	} else{
		$self->param('login' => 0);
	}

	# Create the stash for future use
	$self->param('stash', {});
}

sub setup{
	my $self = shift;

	$self->mode_param('mode');
	$self->run_modes(
			 'view' => '',
			 'custom' => '',
			 'default' => 'default_view',
			 );
	$self->start_mode('default');
}

sub load_template{
	my $self = shift;
	my $template = shift; # Legacy, for now
	$template = $self->param('config')->{'current'}->{'template'} if $self->param('config')->{'current'}->{'template'} && !defined $template;
	if(!defined($template)){
		$self->fatal_error('Passed undefined template to load_template!');
	} elsif(!defined($self->param('config')->{'template_dir'})){
		$self->fatal_error('Could not determine template directory! Check your configuration.');
	}
	$self->param('template' => HTML::Template->new(
		filename => $template,
		path => [
			$self->param('config')->{'template_dir'},
		],
	));
}

sub auth_check{
	my $self = shift;
	if($self->param('login')){
		return "You must log in";
	} else{
		return undef;
	}
}

sub db_connect{
	my $self = shift;
	$self->param('hddb',
			DBI->connect('dbi:'. $self->param('config')->{'db_type'} .':dbname='.$self->param('config')->{'db_name'},
				$self->param('config')->{'db_user'},
				$self->param('config')->{'db_password'},
				{'RaiseError'=>1,'AutoCommit'=>1},
			),
		) or die $DBI::errstr;
	if(!$self->param('hddb')){
		die "$self: mayday mayday!\n";
	}
}

sub load_config{
	my $self = shift;
	my $ref = YAML::LoadFile('config.yml');

	my %form = $self->form_to_variables;
	if($form{'cfg'}){
		# This only happens to refer to the right directory
		if(-f 'config-'.$form{'cfg'}.'.yml'){
			my $overload = YAML::LoadFile('config-'.$form{'cfg'}.'.yml');
			$ref = $self->combine($ref,$overload);
		}
	}
	$self->param('config',$ref);
#die Data::Dumper::Dumper $self->param('config');
#die Data::Dumper::Dumper $ref;
	$self->param('app', $self->param('config')->{'default_app'});
}

sub default_view{
	my $self = shift;
}

# Used to merge two YAML config files together into one data structure
sub combine{
	my $self = shift;
	my $r1 = shift;
	my $r2 = shift;

	foreach my $k (keys %{$r2}){
		if($r2->{$k} =~ /HASH/){
			$r1->{$k} = $self->combine($r1->{$k},$r2->{$k});
		} else{
			$r1->{$k} = $r2->{$k};
		}
	}
	return $r1;
}

##
## internal
##

sub school_from_ip{
	my $self = shift;
	my $IP = $self->query->remote_host();;
	if($IP =~ /^10\./){
		my (@octet) = split(/\./,$IP);
		$IP = $octet[1];
	} else{
		$IP = 0;
	}
	return $IP;
}


sub fatal_error{
	my $self = shift;
	my $err = shift;
	croak $err;
}

sub form_to_variables{
	my $self = shift;
	my @names = $self->query->param;

	my %form;
	foreach my $name (@names){
		$form{$name} = $self->query->param($name);
	}
	return %form;
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

sub match_any{
	my $self = shift;
	my $match = pop;
	my @list = @_;
	foreach my $v (@list){
		return 1 if $v eq $match;
	}
	return undef;
}

sub uniq{
	my $self = shift;
	my @in = @_;
	my %saw;
	undef %saw;
	my @out =  grep(!$saw{$_}++, @in);
	return @out;
}


sub fill{
	my $self = shift;
	my $match = shift;
	my $form = $self->param('form');
	my %FORM = $self->form_to_variables();

	my $record_exists = 0;

	my $sql = $self->form_to_sql($match,$form);
	unless($sql){
		warn "fill: SQL empty";
		return undef;
	}

	my %loopsql = $self->get_loop_sqls($form);

	my @labels_and_names = $self->get_template_name_to_label_mapping($form);
	my @loop_objects = $self->get_loop_objects($form);

	my $result = $self->param('hddb')->selectrow_hashref($sql) if $sql;
#die Data::Dumper::Dumper $result;
	foreach my $label (keys %{$result}){
		$record_exists++;

#die Data::Dumper::Dumper @labels_and_names;

		# Fill regular H::T vars
		foreach my $mapping (@labels_and_names){
			if($mapping->{'label'} eq $label){
				# need both data and a place to put it
				if($mapping->{'db_field'} && $mapping->{'ht_field'}){
					if($self->param('template')->query('name' => $mapping->{'ht_field'})){
						$self->param('template')->param($mapping->{'ht_field'},$result->{$label});
						last;
					} else{
						# We asked for a non-existant HTML::Template field
						warn "fill: ".$mapping->{'ht_field'}." requested but not found in template.";
					}
				}
			}
		}
		# Fill loop H::T vars
		foreach my $lobj (@loop_objects){
			if($lobj->{'value_from_db_field'} eq $label){
				# Form, SQL, Loopname, Match value
				$self->insert_loop_into_template($form,$loopsql{$lobj->{'loopname'}},$lobj->{'loopname'},$result->{$label});
				last;
			}
		}

	}
	
	return $record_exists;
}


sub populate_template_from_stash{ # aka fill2
	my $self = shift;
	my $match = shift;

#	my ($form,$label,$result,%loopsql); # To prevent parse errors
	my $record_exists = 0;

#	my @labels_and_names = $self->get_template_name_to_label_mapping($form);
#	my @loop_objects = $self->get_loop_objects($form);

	my $page = $self->param('stash')->{'page'};

	# $page holds a hierarchy. Each TMPL_VAR is a key with a value (hash). Each TMPL_LOOP is a key with a 
	# {'array'=>['',''],'default'=>''} as a value. 'default' might be either the value or the key (haven't 
	# decided yet) and is used (at least) to determine which is selected.


	foreach my $var (keys %{$page}){
		$record_exists++;
		if(ref $page->{$var} =~ /HASH/){
			# Not a simple key/value. Some kind of hashref
			if($page->{$var}->{'array'} && !ref $page->{$var}->{'array'}){
				# If we have an array element which isn't a simple variable then this is a LOOP.
				# populate_loop will scan through it and also descend into any loops that it
				#  contains (recursively) adding them to the template.
				$self->populate_loop($page->{$var}->{'array'},$page->{$var}->{'default'});
			}
			# More checks for other types of structures go here.
		}

		if($self->param('template')->query('name' => $var)){
			 $self->param('template')->param($var, $page->{$var});
		}
	}

	return $record_exists;
}

# Form Object, SQL query to run, Loop Name to populate, List entry to select.
sub insert_loop_into_template{
	my $self = shift;
	my $form = shift;
	my $sql = shift;
	my $loopname = shift;
	my $match = shift;

	my $thisloop = $form->{'lists'}->{$loopname};

	my $sth = $self->param('hddb')->prepare($sql);

      	$sth->execute();
	my @entries;

	my $selectval = $match;
	# Could do this here if eval stuff fails below. But it didn't. w00t
	#if($thisloop->{'value_from_db_field'} eq 'School'){
	#	$thisloop->{'default_selected'} = $self->school_from_ip() || $thisloop->{'default_selected'};
	#}
	$selectval = $thisloop->{'default_selected'} if !defined $selectval;

        while(my $hrrow = $sth->fetchrow_hashref()){
		my %row;

		my @loop_vars = $self->param('template')->query(loop => $loopname);
		foreach my $lv (@loop_vars){
			next unless $lv; # We can't do aught with empty strings. In fact, they should never show up!

			# Hairy! Execute specified function via eval() and pass it $lv
			if($thisloop->{'select_from_function'}){
				my $sel = eval(
					'$self->'.($thisloop->{'select_from_function'}).'("'.($hrrow->{$lv}).'");'
					);
				$selectval = $sel;
			}

			# If this is the field we select with...
			if($lv eq $thisloop->{'select_with'}){
				$row{$thisloop->{'select_with'}} = '';
				if($hrrow->{$lv} eq $selectval){
					# Add ' selected' to this <option>
					$row{$thisloop->{'select_with'}} = ' selected';
				}
			} else{
				# Everything else, pass right through
				if(defined $hrrow->{$lv}){
					$row{$lv} = $hrrow->{$lv};
				} else{
					if($lv){
						warn "Resultant hash from select for $loopname has no record for $lv: " . Data::Dumper::Dumper @loop_vars;
					} else{
						warn "variable lv empty: this should not happen"
					}
				}
			}
		}
		push(@entries,\%row);
	}
	if($self->param('template')->query(name => $loopname)){
		$self->param('template')->param($loopname => [@entries]);
	} else{
		# No error. Just ignore it
#		$self->throw_error("Loop variable $loopname not found in template.");
	}
}

sub get_template_name_to_label_mapping{
	my $self = shift;
	my $form = shift;
	my @fields;
	if($form->{'fields'}){
		foreach my $k (keys %{$form->{'fields'}}){
			foreach my $m (@{$form->{'fields'}->{$k}}){
				if($m->{'ht_field'}){ # If ht_field is not specified this is probably filled via a loop
					my %h;
					$h{'label'} = $m->{'as'};
					$h{'ht_field'} = $m->{'ht_field'};
					$h{'html_field'} = $m->{'html_field'} if $m->{'html_field'};
					$h{'db_field'} = $m->{'db_field'} if $m->{'db_field'};
					push(@fields,\%h);
				}
			}
		}
		return @fields;
	} else{
		return ();
	}
}

# *definitely* a View function.
sub set_self_url{
	my $self = shift;

	if($self->param('template')){
		if($self->param('template')->query('name' => 'self_url')){
			$self->param('template')->param('self_url' => $self->query->url);
		}
		if($self->param('template')->query('name' => 'cfg')){
			$self->param('template')->param('cfg' => $self->param('cgi')->{'cfg'});
		}
		if($self->param('template')->query('name' => 'app')){
			$self->param('template')->param('app' => $self->param('cgi')->{'app'});
		}
		if($self->param('template')->query('name' => 'mode')){
			$self->param('template')->param('mode' => $self->param('cgi')->{'mode'});
		}
	}
}

sub throw_error{
	my $self = shift;
	my $err = shift;

	$err .= '<TMPL_VAR NAME="catch_errors">';
	if($self->param('template') && $self->param('template')->query(name => 'catch_errors')){
		$self->param('template')->param('catch_errors' => $err);
	} else{
		croak $err;
	}
}

sub get_loop_sqls{
	my $self = shift;
	my $form = shift;
	# TWO variables confusingly both named form?! Hell yes!
	my %form = $self->form_to_variables();

	my $lists = $form->{'lists'};

	return {} unless $lists;

	# Construct SQL for each of the lists specified in the .form
	my %sqls;

	foreach my $k (keys %{$lists}){
		my $v = $lists->{$k};
#die Data::Dumper::Dumper $v unless $v->{'comparison'};
		my $sql = 'select ';

		# If the list needs to be limited somehow, construc a where clause
		my $where = ' ';
		if($v->{'where'}){
			if(!defined $v->{'comparison'}){
				warn "List $k has no comparion though it has a where!";
			}
			my $op = $self->operator_txt_to_operator($v->{'comparison'});

			my $pattern = $self->operator_txt_to_pattern($v->{'comparison'});

			my $val = $v->{'wherevalue'};
			if( defined($form{$v->{'value_from_html_field'}}) ){
				$val = $form{$v->{'value_from_html_field'}};
			}
			$val =  $self->param('hddb')->quote($val);
			$pattern =~ s/\*/$val/;

			$where = " where $v->{'table'}.$v->{'where'} $op $pattern";
		}

		$sql = "select $v->{'fields'} from $v->{'table'}$where order by $v->{'sort'};";
		$sqls{$k} = $sql;
	}

#	# Run each block of SQL and associate results into the HTML::Template via the .form info
#	foreach my $loopname (keys %sqls){
#		$self->insert_loop_into_template($form,$sqls{$loopname},$loopname,undef);
#	}
# This is MUCH better done later in a more context-aware environment!

	return %sqls;
}

# Gets loop objects from form passed as first argument. Returns an array of those objects.
sub get_loop_objects{
	my $self = shift;
	my $form = shift;
	my @loops;
	if($form->{'lists'}){
		foreach my $k (keys %{$form->{'lists'}}){
			$form->{'lists'}->{$k}->{'loopname'} = $k;
			push(@loops,$form->{'lists'}->{$k});
		}
	}
	return @loops;
}

# Set essential member variables which are relied on by many different methods
sub populate_params{
	my $self = shift;
	my $script = shift;

	my %form = $self->form_to_variables;
	$self->param('cgi', \%form);

	$self->param('cfg' => $form{'cfg'});
	$self->param('app' => $form{'app'});
	$self->param('mode' => $form{'mode'});

#	unless($self->param('config')->{'config_dir'}){
#		$self->fatal_error("Unable to see config_dir\n");
#	}
#	unless($self->param('config')->{'pnd'}->{$self->param){
#
#	}
#die Data::Dumper::Dumper $self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{$script}->{$self->param('cgi')->{'mode'}};

	if($self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{$script}->{$self->param('cgi')->{'mode'}}->{'form'}){
		my $form = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{$script}->{$self->param('cgi')->{'mode'}}->{'form'});

		$self->param('form', $form);

#die Data::Dumper::Dumper $form unless $form->{'primarytable'};
#die Data::Dumper::Dumper $form;
#die Data::Dumper::Dumper $script;
#die Data::Dumper::Dumper $form->{'where'}->{$form->{'primarytable'}};

		if(defined $form->{'primarytable'}){
			$self->param('select_db_field',$form->{'where'}->{$form->{'primarytable'}}->{'db_field'});
			$self->param('select_ht_field',$form->{'where'}->{$form->{'primarytable'}}->{'ht_field'});
			$self->param('select_html_field',$form->{'where'}->{$form->{'primarytable'}}->{'html_field'});
		} else{
			warn "form->{'primarytable'} not set in " .$self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{$script}->{$self->param('cgi')->{'mode'}}->{'form'};
		}
	}

	$self->param('pnd', $self->param('config')->{'pnd'}->{$self->param('cgi')->{'app'}}->{$script}->{$self->param('cgi')->{'mode'}});
}


###############################################################################
######### Functions which work with comparison objects and .cmps files ########
###############################################################################

# Main worker function which is called by the more friendly-named functions below.
sub operator_extract{
	my $self = shift;
	my $from = shift;
	my $to = shift;
	my $wanted_op = shift;

	my $ops = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'comparisons'});

	my @ops = @{$ops->{'comparisons'}};

	my $op = ' "INVALID OPERATOR '.($wanted_op?$wanted_op:'UNKNOWN').'"';
	foreach my $o (@ops){
		my ($key) = (keys %{$o});
		if(defined $o->{$key}->{$from} && defined $wanted_op){
			if($o->{$key}->{$from} eq $wanted_op){
				$op = $o->{$key}->{$to};
				last;
			}
		} else{
			warn "Undef while extracting from $from to $to operator. Key=$key, o=".(defined $o?1:0);
		}
	}
	return $op;
}

sub operator_txt_to_pattern{
	my $self = shift;
	my $pat = shift;
	return $self->operator_extract('txt','pattern',$pat);
}
sub operator_txt_to_operator{
	my $self = shift;
	my $txt_op = shift;
	return $self->operator_extract('txt','sql',$txt_op);
}
sub operator_sql_to_txt{
	my $self = shift;
	my $wanted = shift;
	return $self->operator_extract('sql','txt',$wanted);
}
sub operator_sql_to_pattern{
	my $self = shift;
	my $wanted = shift;
	return $self->operator_extract('sql','pattern',$wanted);
}


###############################################################################
######### Functions for handling .form files and making SQL from them. ########
###############################################################################

sub form_to_sql{
	my $self = shift;
	my $match = shift;
	my $form = shift;

	my $sql = '';

	# call _join_to_sql and _fields_to_sql to generate correct sql ...
	my $joins = $self->form_join_to_sql($form->{'join'});
	my $fields = $self->form_fields_to_sql($form->{'fields'});
	my $tables = $self->form_tables_to_sql($form->{'tables'});
	my $where = $self->form_where_to_sql($form->{'where'}->{$form->{'primarytable'}});
	# Do this in two steps so perl doesn't get confused.
	my $v = $self->param('hddb')->quote($match);
	$where =~ s/\*/$v/;

	# In reality sort doesn't matter because everything assumes only one matching record.
	my $sort = $self->form_order_to_sql($form->{'sort'});

	# generate other necessary sql
	if($fields){
		# If you have no fields to select it's not valid SQL. select from table where exp order by fields; = invalid
		$sql .= $fields.' ';
		if($tables){
			$sql .= 'from '.$tables.' ';
		} else{
			# MUST have tables! Throw a graceful(ish)--at any rate, non-raw-perl--error.
			die 'form_to_sql: Tried constructing an SQL select without table references. Check validity of your .form file';
		}
		if($joins){
			$sql .= $joins.' ';
		}
		if($where){
			$sql .= 'where '.$where.' ';
		}
		if($sort){
			$sql .= 'order by '.$sort;
		}
		if($sql){
			$sql = 'select '.$sql.';';
		}
	}

	return $sql;
}

sub form_order_to_sql{
	my $self = shift;
	my $sobj = shift;
	my @sort;
	foreach my $field (@{$sobj}){
		push(@sort,$field);
	}
	return join(', ',@sort);
}


sub form_where_to_sql{
	my $self = shift;
	my $wobj = shift;

	if($wobj && $wobj->{'comparison'}){
		# select... where
		# table.field
		my $sql = $wobj->{'table'}.'.'.$wobj->{'db_field'}.
		# =
		' '.$self->operator_txt_to_operator($wobj->{'comparison'}).
		# value
		' '.$self->operator_txt_to_pattern($wobj->{'comparison'});

		return $sql;
	}
	undef;
}

sub form_tables_to_sql{
	my $self = shift;
	my $tobj = shift;

	my @tables;
	foreach my $t (@{$tobj}){
		push(@tables,$t);
	}

	return join(', ',@tables);
}


sub form_fields_to_sql{
	my $self = shift;
	my $fobj = shift;

	if($fobj){
		my (@fields,@tables);
		foreach my $table (keys %{$fobj}){
			foreach my $field (@{$fobj->{$table}}){
				my $sql = $field->{'db_field'}.' as '.$self->param('hddb')->quote($field->{'as'});
				push(@fields,$sql);
			}
			push(@tables,$table);
		}
		return join(', ',@fields);
	} else{
		return '';
	}
}

sub form_join_to_sql{
	my $self = shift;
	my $joinobj = shift;
	my $sql = '';
	# work on join object to extract correct SQL ... 
	my @joins;
	if($joinobj){
		foreach my $join (@{$joinobj}){
			if($join){
				my $operator = $self->operator_txt_to_operator($join->{'on'}->{'comparison'});
				my $sql = $join->{'type'}.' join '.$join->{'table'}.' on ('.$join->{'on'}->{'source'}.' '.$operator.' '.$join->{'on'}->{'dest'}.')';
				push(@joins,$sql);
			}
		}
		return join(' ',@joins);
	} else{
		return '';
	}
}


# Converts a named HTML fieldname into the corrosponding html::template variable name (using a .form file)
sub html_field_to_ht_field{
	my $self = shift;
	my $fobj = shift;
	my $match = shift;

	my (@fields);
	foreach my $table (keys %{$fobj}){
		foreach my $field (@{$fobj->{$table}}){
			if($match eq $field->{'html_field'} && $field->{'ht_field'}){
				return $field->{'ht_field'};
			}
		}
	}
	return undef;
}
1;
