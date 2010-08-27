#!/usr/bin/perl

# CCBOE Helpdesk Scripts
# Report.pm - Generate reports from the database
# By Clark Buehler (cbuehler@ccboe.com)

package CCBOEHD::Report;
use base qw(CCBOEHD::Base);

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
## This would go in the base module in catalyst (e.g. CCBOE/Technology.pm)
## or, some would go in CCBOE/Technology/View/HT.pm (because it's vew-specific)
## some may go in CCBOE/Technology/Model/* (mysql DB connect stuff)
##

sub setup
{
	my $self = shift;

	$self->start_mode('welcome');
	$self->mode_param('mode');
	$self->run_modes(
		'custom' => 'custom_view',
		'date' => 'date_view',
		'report' => 'report_view',
		'welcome' => 'welcome_view',
	);
	$self->load_config;
	$self->db_connect;
}


## 
## Interface functions
## 

sub custom_view{
	my $self = shift;

	my %form = $self->form_to_variables();
	$self->param('config')->{'current'}->{'template'} = $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'custom'}->{'template'};
	$self->load_template;

	$self->param('template')->param('self_url' => $self->query->url);

	$self->populate_params('report.pl');
	$self->set_self_url;

	my $y = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'});
	$self->param('report',$y);

	$self->param('config')->{'current'}->{'rmap'} = $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'custom'}->{'rmap'};

	$self->fill_select_form;


	return $self->param('template')->output();
}

sub report_view{
	my $self = shift;
	my %form = $self->form_to_variables;

	$self->param('config')->{'current'}->{'template'} = $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'template'};
	$self->load_template;
	$self->param('template')->param('self_url' => $self->query->url);

	$self->populate_params('report.pl');
	$self->set_self_url;

	my $y = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'});

	$self->param('report',$y);

	$self->fill_select_form;

	$self->param('config')->{'current'}->{'form'} = %form;

	$self->make_sql_from_form_submit;

	$self->find_primary_key_column;

	my $sth = $self->param('hddb')->prepare($self->param('stash')->{'sql'});
	$sth->execute();

	# Label of the Primary Key's field is the column header to look for in the results
	my $info = $self->get_the_damn_field($self->param('report')->{'primarykey'});
	$self->param('stash')->{'db'}->{'fahr'} = $sth->fetchall_hashref($info->{'label'}); # FAHR = FetchAllHashRef. I'm so clever!

	# Find the index of the column containing the primary key for this table.
	my $pk_col = $self->param('config')->{'current'}->{'primary_key_column'};
	# Grab an array of primary keys
	$self->param('stash')->{'db'}->{'primary_keys_to_display'} = $self->param('hddb')->selectcol_arrayref($self->param('stash')->{'sql'}, { Columns=>[$pk_col] });

	$self->param('config')->{'current'}->{'rmap'} = $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'report'}->{'rmap'};

	$self->fill_results_loop;

	return $self->param('template')->output();
}

sub welcome_view{
	my $self = shift;
	$self->query->param('mode' => 'welcome');
	$self->populate_params('report.pl');

	my %form = $self->form_to_variables;

	$self->param('config')->{'current'}->{'template'} = $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'welcome'}->{'template'};
	$self->load_template;

	$self->set_self_url;

#die Data::Dumper::Dumper $self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->{'welcome'}->{'rmap'});

	my $y = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'pnd'}->{$form{'app'}}->{'report.pl'}->
															{'welcome'}->{'form'});
	$self->param('report-welcome',$y);

	# Generate/Populate the School and Status select form.

	$self->fill($self->school_from_ip()||1);

	# Generate the Date Select form

	# .. put stuff here ...

        return $self->param('template')->output();
}

sub date_view{
	my $self = shift;
	return qq(<html><head><title> Under construction </title></head><body><h1>Under construction</h1><p>Try back later.</p></body></html>);
}

## 
## Internal functions
## 

# fill_loop appears to be no longer used anywhere (2/6/2006). I don't remember replacing it or writing it out so I am commenting it out until I can figure out whether it's needed
# I think perhaps this was a special case to populate the welcome page back when there was only one. I later extended .forms and fill() to handle the welcome page as well
#sub fill_loop{
#	my $self = shift;
#	my $loopname = shift;
#
#	my $y = $self->param('report-welcome');
#
#	my @col;
#
#	foreach my $f (@{$y->{'fields'}}){
#		my ($key) = keys %{$f};
#		my %fields = %{$f->{$key}};
#
#		my $sql;
#
#		$sql .= "select ".($fields{'field'})." from ".($fields{'table'});
#
#		if($fields{'where'} && defined($fields{'value'}) && $fields{'compare'}){
#			my %cmp = $self->lookup_cmp(
#					$y->{'comparisons'},
#					$fields{'compare'},
#				  );
#			$sql .= " where ".($fields{'where'})." ".($cmp{'sql'})." ".($self->param('hddb')->quote($fields{'value'}));
#		}
#
#		if($fields{'sort'}){
#			$sql .= " order by ".($fields{'sort'});
#		}
#
#		$sql .= ';';
#		my $sth = $self->param('hddb')->prepare($sql);
#		$sth->execute();
#
#		my $selected = $self->school_from_ip; # Get the current school number, if any
#
#		my @entries;
#		while(my $data = $sth->fetchrow_hashref()){
#			my %row;
#			$row{'txt'} = $data->{'txt'};
#			$row{'lbl'} = $data->{'lbl'};
#			$row{'sel'} = '';
#			$row{'sel'} = ' selected' if $data->{'sel'} eq $selected ;
#			push(@entries,\%row);
#		}
#		$self->param('template')->param($fields{'varname'} => [@entries]);
#
#	}
#
#	my @now = localtime(time);
#
#	my @bsec = $self->numeric_selector(0,59,0,'%02d');
#	my @esec = $self->numeric_selector(0,59,$now[0],'%02d');
#
#	my @bmin = $self->numeric_selector(0,59,0,'%02d');
#	my @emin = $self->numeric_selector(0,59,$now[1],'%02d');
#
#	my @bhr = $self->numeric_selector(0,23,0,'%02d');
#	my @ehr = $self->numeric_selector(0,23,$now[2]+1,'%02d');
#
##die Data::Dumper::Dumper @now;
#	my @bday = $self->numeric_selector(1,31,0,'%02d');
#	my @eday = $self->numeric_selector(1,31,$now[3],'%02d');
#
#	my @bmonth = $self->numeric_selector(1,12,0,'%02d');
#	my @emonth = $self->numeric_selector(1,12,$now[4]+1,'%02d');
#
#	my @byr = $self->numeric_selector(2001,$now[5]+1900,$now[5]+1900,'%4d');
#	my @eyr = $self->numeric_selector(2001,$now[5]+1900,$now[5]+1900,'%4d');
#
#	$self->param('template')->param('bsec' => [@bsec]);
#	$self->param('template')->param('esec' => [@bsec]);
#
#	$self->param('template')->param('bmin' => [@bmin]);
#	$self->param('template')->param('emin' => [@emin]);
#
#	$self->param('template')->param('bhour' => [@bhr]);
#	$self->param('template')->param('ehour' => [@ehr]);
#
#	$self->param('template')->param('bday' => [@bday]);
#	$self->param('template')->param('eday' => [@eday]);
#
#	$self->param('template')->param('bmonth' => [@bmonth]);
#	$self->param('template')->param('emonth' => [@emonth]);
#
#	$self->param('template')->param('byear' => [@byr]);
#	$self->param('template')->param('eyear' => [@eyr]);
#
#
#	return @col;
#
#}

# Currently unused. Might as well keep it since it will be used eventually when I get back to the date reporting (at least).
# Definitely a Controller kind of function, I think. maybe View
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

sub lookup_cmp{
	my $self = shift;
	my $c = shift;
	my $lookup = shift;

	my %found;
	foreach my $cmp (@{$c}){
		my ($cmpname) = keys %{$cmp};
		if($cmpname eq $lookup){
			%found = %{$cmp->{$cmpname}};
			last;
		}
	}
	return %found;;
}


# Count forward in the list of selected columns and find the index of the column
# listed as the primary key for the primary table (as specified in the config)
sub find_primary_key_column{
	my $self = shift;
	my $sql = $self->param('stash')->{'sql'};

	my $pkeycol = ($self->param('report')->{'primarytable'}).'.'.($self->param('report')->{'primarykey'});

	$sql =~ s/select //;
	$sql =~ s/ from .*//;
	my @fields = split(/,/,$sql);
	my $n;
	for(my $i=0;$i<@fields;$i++){
		if($fields[$i] =~ /$pkeycol/){
			$n = $i+1;
			last;
		}
	}
	$self->param('config')->{'current'}->{'primary_key_column'} = $n;
	return $n; # Legacy
}

sub find_column_order{
	my $self = shift;
	my @all = @_;
	my %form = $self->form_to_variables;

	my @sortable_columns = $self->cols_with_attribute('sort');
	my @ordered;
	# The (huge) array @sort goes out of scope sooner this way
	do{
		my @sort = sort { $a cmp $b } grep { /^sort.*/ } keys %form;
		@ordered = map { $_ = $form{$_} } @sort;
	};
	my @correct = $self->uniq(@ordered,@sortable_columns);

	return @correct;
}

# Remove from array ref $list all elements in array ref $remove and return the
# resultant array
sub remove_intersection{
	my $self = shift;
	my $list = shift;
	my $remove = shift;

	my %h = map { $_ => 1 } @{$list};

	foreach my $elem (@{$remove}){
		delete $h{$elem};
	}

	return keys %h;
}

# This seems like a View or Controller function to me.
sub fill_results_loop{
	use Time::HiRes qw / gettimeofday / ; # required for reporting query time
	my $now = [Time::HiRes::gettimeofday()];

	my $self = shift;
	my $sql = $self->param('stash')->{'sql'}; 
	my $file = $self->param('config')->{'current'}->{'rmap'}; # the .rmap file name

#die $sql;
	my (@loop, @header, @head);
	$self->param('stash')->{'db'}->{'number_of_records_selected'} = 0;

	if($sql){
		# Label of the Primary Key's field is the column header to look for in the results
		my $fahr = $self->param('stash')->{'db'}->{'fahr'}; # FAHR = FetchAllHashRef. I'm so clever!
		my $keys_to_display = $self->param('stash')->{'db'}->{'primary_keys_to_display'};

		my @columns_in_order = $self->find_column_order;
		my @shown_columns = $self->cols_with_attribute('show');
		my @suppressed_columns = $self->cols_with_attribute('suppress');

		# Add to shown columns and columns used in where clause of select:
		@shown_columns = ($self->uniq($self->field_names_requested_in_form_submit,@shown_columns));

		# Remove from shown columns any columns listed as 'suppress':
		@shown_columns = ($self->remove_intersection(\@shown_columns,\@suppressed_columns));

#		die Data::Dumper::Dumper $keys_to_display;

		foreach my $pkey (@$keys_to_display){
			my @cols;
			foreach my $k (@columns_in_order){
				if($self->match_any(@shown_columns,$k)){
					my ($lbl) = ($self->labels_for_cols($k));
					push(@cols,{'colval' => $fahr->{$pkey}->{$lbl}});
					push(@head,$lbl);
				}
			}
			push(@loop,{
				'col' => [@cols],
				$self->param('report')->{'primarykey'} => $pkey,
			});
		}

		$self->param('stash')->{'output'}->{'show_results'} = 1;
		$self->param('stash')->{'db'}->{'number_of_records_selected'} = scalar(@$keys_to_display) if $keys_to_display;
	}


	@head = $self->uniq(@head);
	foreach my $he (@head){
		push(@header,{'name'=>$he});
	}

	$self->param('stash')->{'output'}->{'column_headers'} = \@header;
	$self->param('stash')->{'output'}->{'data_table'} = \@loop;

	$self->param('stash')->{'db'}->{'record_select_time_elapsed'} = Time::HiRes::tv_interval($now);

	# The rest is technically stuff for the View.

	# Could probably also use results != 0 here and save some memory.
	if($self->param('stash')->{'output'}->{'show_results'}){
		$self->param('template')->param('showresults',$self->param('stash')->{'output'}->{'show_results'} );
	}

	$self->param('template')->param('header',[@{$self->param('stash')->{'output'}->{'column_headers'}}]);

	$self->param('template')->param('row',[@{$self->param('stash')->{'output'}->{'data_table'} }]);


	$self->param('template')->param('selected_rows',$self->param('stash')->{'db'}->{'number_of_records_selected'});
	$self->param('template')->param('selected_time',sprintf("%.3f", $self->param('stash')->{'db'}->{'record_select_time_elapsed'} ));
}

sub remove_empties{
	my $self = shift;
	my @ar = @_;
	my @out;
	foreach my $v (@ar){
		if(defined $v){
			if($v ne ''){
				# Empty string is okay
			} else{
				next;
			}
		} else{
			next;
		}
		push(@out,$v);
	}
	return @out;
}

# How many form fields with names starting $basename had values?
sub how_many_filled{
	my $self = shift;
	my $basename = shift;
	my %form = $self->form_to_variables;
	my @r = grep { /^$basename.*/ } keys %form;
	@r = map { $_ = $form{$_} } @r;
	@r = $self->remove_empties(@r);
	return scalar(@r);
}

### Begin block of new functions for cross table join

sub column_ids_from_map{
	my $self = shift;
	my $y = $self->param('report');

	my @col;
	foreach my $f (@{$y->{'fields'}}){
		my ($key) = keys %{$f};
		push(@col,$key);
	}
	return @col;
}

# Find columns with attribute $attr in data structure $self->param('report')
sub cols_with_attribute{
	my $self = shift;
	my $attr = shift;
	my $y = $self->param('report');

	my @all = $self->column_ids_from_map;
	my @matches;
	foreach my $f (@all){
		my @attributes;
		foreach my $field (@{$y->{'fields'}}){
			if($field->{$f}){ # Otherwise when we reference $field->{$f} it creates it
				my $c = $field->{$f}->{'column'};
				if($c){
					@attributes = @{$c};
				}
			}
		}
		if($self->match_any(@attributes,$attr)){
			push(@matches,$f);
		}
	}

	return @matches;
}

sub labels_for_cols{
	my $self = shift;
	my @cols = @_;
	my @labels;
	foreach my $f (@cols){
		my $h = $self->get_the_damn_field($f);
		push(@labels,$h->{'label'});
#		foreach my $h (@{$self->param('report')->{'fields'}}){
#			if($h->{$f}){
#				push(@labels,$h->{$f}->{'label'});
#			}
#		}

	}
#die Data::Dumper::Dumper @labels;
	@labels = $self->uniq(@labels);
#die Data::Dumper::Dumper @labels;
	return $self->uniq(@labels);
}


# This is a big one. Big, overly complicated, and harder to understand then necessary 
# it merely creates the HTML forms at the top of the report page where you choose what 
# to select with and sort by.
sub fill_select_form{
	my $self = shift;

	my @shown_columns = $self->cols_with_attribute('show');
	my @selectable_columns = $self->cols_with_attribute('select');
	my @sortable_columns = $self->cols_with_attribute('sort');
	my @all_columns = $self->uniq(@shown_columns, @selectable_columns, @sortable_columns);

	my @selectable_column_labels = $self->labels_for_cols(@selectable_columns);
	my @sortable_column_labels = $self->labels_for_cols(@sortable_columns);
	my @all_column_labels = $self->labels_for_cols(@all_columns);

	my %form = $self->form_to_variables;

	# Set the number of fields to show (1 or the number you used in your query)
	my $filled = $self->how_many_filled('query');
	my $s_filled = $self->how_many_filled('sort');

	# Set the max fields availible to the number of shown columns... should never need more.
	my $max = scalar(@shown_columns);
	if($filled > $max){ # Cannot fill more fields than we have! And it b0rks the JS.
		$filled = $max;
	}
	if($s_filled > $max){ # Cannot fill more fields than we have! And it b0rks the JS.
		$s_filled = $max;
	}

	$filled = 1 if ! $filled;
	$s_filled = 0 if ! $s_filled;

	$self->param('template')->param('filled_fields',$filled);
	$self->param('template')->param('filled_sorted_fields',$s_filled);
	$self->param('template')->param('max_fields',$max);


	# Grab an array of hashrefs which are the comparisons
	my @cmp = $self->get_cmps;

	# Take care of looking up comparison labels and values here
	my (@cmpvalues,@cmplabels);

	foreach my $o (@cmp){
		my ($key) = keys %{$o};
		push(@cmpvalues,$key);
		push(@cmplabels,$o->{$key}->{'txt'});
	}

	# And/Or labels and values hardcoded here. Very simple indeed.
	my @ao_labels = qw(and or);
	my @ao_values = qw(and or);

	my @vals = sort { $a cmp $b } grep { /^query.*/ } keys %form;

	# It is somewhat difficult to get everything to line up properly

	my @used_field_names;
	my @used_query_vals;
	my @used_comparison_names;
#	my @used_andor_names;
	for(my $i=0;$i<@vals;$i++){
		if(defined($form{'query'.$i}) and $form{'query'.$i} ne ''){
			push(@used_field_names,$form{'field'.$i});
			push(@used_query_vals,$form{'query'.$i});
			push(@used_comparison_names,$form{'comparison'.$i});
#			push(@used_andor_names,$form{'andor'.$i});
		}
	}

	my(@bmarks); # Bookmark
	my @loop; # Select
	for(my $i=0;$i<@all_columns;$i++){
		my %r; # row.
		$r{'seq'} = $i;
#		$r{'query'} = $self->decide('query',$i,'',%form);
		$r{'query'} = shift @used_query_vals;

		if($self->match_any(@selectable_columns,$all_columns[$i])){
			@{$r{'select_values'}} = $self->selectorify(\@selectable_column_labels, \@selectable_columns,$used_field_names[$i] || $selectable_columns[$i]);
			@{$r{'select_comparisons'}} = $self->selectorify(\@cmplabels,\@cmpvalues, $used_comparison_names[$i] || $form{'comparison'.$i} || 'like');
			@{$r{'andor'}} = $self->selectorify(\@ao_labels,\@ao_values, $form{'andor'.$i} || 'and');
#			@{$r{'andor'}} = $self->selectorify(\@ao_labels,\@ao_values, $used_andor_names[$i], $form{'andor'.$i} || 'and');


			# Bookmarkability section
			if(defined $r{'query'} && $r{'query'} ne ''){
				my(%bmark_q, %bmark_ao, %bmark_cmp, %bmark_f);
				$bmark_f{'key'} = 'field'.$i;
				$bmark_f{'value'} = $used_field_names[$i] || $selectable_columns[$i];

				$bmark_q{'key'} = 'query'.$i;
				$bmark_q{'value'} = $r{'query'};

				$bmark_ao{'key'} = 'andor'.$i;
				$bmark_ao{'value'} = $form{'andor'.$i};

				$bmark_cmp{'key'} = 'comparison'.$i;
				$bmark_cmp{'value'} = $used_comparison_names[$i] || $form{'comparison'.$i} || 'like';

				push(@bmarks,\%bmark_q,\%bmark_ao, \%bmark_cmp, \%bmark_f);
			}

			push(@loop,\%r);
		}
	}

	my @sloop; # Sort
	for(my $i=0;$i<@all_columns;$i++){
		my %r;
		$r{'seq'} = $i;
#		$r{'query'} = $self->decide('query',$i,'',%form);

# We used to want to select a successive sort value for each one. Now we just select the empty value by default.
#		@{$r{'select_sort'}} = $self->selectorify( \@sortable_column_labels,\@sortable_columns, $form{'sort'.$i} || ($sortable_columns[$i])); 
		@{$r{'select_sort'}} = $self->selectorify( \@sortable_column_labels,\@sortable_columns, $form{'sort'.$i} || ''); 

		if($form{'sort'.$i}){
			my %bmark_sort;
			$bmark_sort{'key'} = 'sort'.$i;
			$bmark_sort{'value'} = $form{'sort'.$i};
			push(@bmarks,\%bmark_sort);
		}
		push(@sloop,\%r);
	}

	# Stick the HTML forms into the template
	$self->param('template')->param('sort_loop',[@sloop]);
	$self->param('template')->param('select_fields',[@loop]);
	if($self->param('template')->query(name => 'bookmarkable') && !$form{'bookmarked'}){
		push(@bmarks,{'key' => 'app', 'value' => $form{'app'}}, {'key' => 'mode', 'value' => $form{'mode'}}, {'key' => 'cfg', 'value' => $form{'cfg'}});
		push(@bmarks,{'key' => 'bookmarked', 'value' => 1});
		$self->param('template')->param('bookmarkable',[@bmarks]);
	}
}


# Usage:
# my $hash = $self->get_the_damn_field('schoolname');
# die $hash->{'label'}; # will report 'School'
#
# This is to get the element of the array of field descriptors which matches a given name
# so that sub-elements of it may be more concisely referenced.
# for example, the alternative to the above example without this function would be:
# die $self->param('report')->{'fields'}->[0]->{'schoolname'}->{'label'};
# but only because schoolname happens to be at index 0.
#die Data::Dumper::Dumper map { my($k,$v) = each %{$_} ; $k => $_->{$k}->{'label'} } @{$self->param('report')->{'fields'}};
sub get_the_damn_field{
	my $self = shift;
	my $requested = shift;

	my @report_fields = @{$self->param('report')->{'fields'}};

	foreach my $field (@report_fields){
		my ($keyname) = keys %{$field};
		if ($keyname eq $requested){
			return $field->{$keyname};
		}
	}

	return {};
}

sub field_names_requested_in_form_submit{
	my $self = shift;
	my %form = $self->form_to_variables();

	my @fields = sort { $a cmp $b } grep { /^field.*/ } keys %form;
	@fields = map { $_ = $form{$_} } @fields;
	my @qs = sort { $a cmp $b } grep { /^query.*/ } keys %form;
	@qs = map { $_ = $form{$_} } @qs;

	my @out;
	for(my $i=0;$i<@qs;$i++){
		if(defined($qs[$i]) and $qs[$i] ne ''){
			push(@out,$fields[$i]);
		}
	}
	return @out;
}

# Search through the form submit for keys beginnig with the specified string
# Sort those keys. 
# Pull the associated values out of the form submit in (now) sorted order.
sub grep_query_convert_to_val{
	my $self = shift;
	my $key = shift;

	my %form = $self->form_to_variables;

	return map { $_ = $form{$_} } sort { $a cmp $b } grep { /^$key.*/ } keys %form;
}

# This is a big one. Converts form submit into a single SQL statement that can be sent to the database.
sub make_sql_from_form_submit{
	my $self = shift;

	# Assure that the stash exists and has an sql variable
	if(!$self->param('stash')){
		my %stash = ('sql' => '');
		$self->param('stash', \%stash);
	}


	my %form = $self->param('config')->{'current'}->{'form'};

	my $y = $self->param('report');

	my @cmps = $self->get_cmps;
	# get_cmps returns an array in case we care about what order the cmps appear in the config file
	# we don't, and it's hard to know N in $cmps[N]->{'is'}->{'txt'} so we transmogrify into a hash here
	my %cmp;
        foreach my $o (@cmps){
		my ($k) = keys %{$o};
		$cmp{$k} = $o->{$k};
        }

	my @col_ids = $self->column_ids_from_map;
#	my @column_labels = $self->labels_for_cols($self->cols_with_attribute('select'));

	# Functions make for easier reading
	my @fields = $self->grep_query_convert_to_val('field');
	my @values = $self->grep_query_convert_to_val('query');
	my @comparison = $self->grep_query_convert_to_val('comparison');
	my @sort = $self->grep_query_convert_to_val('sort');
	my @andor = $self->grep_query_convert_to_val('andor');

	# Look up fields as IDs in the reportmap file, replace each field with its real table field.

	my (@select,@as,@join_type,@join_on,@join_test,@order,@where,@and,%order);
	my @ordered_fields = $self->all_not_in(\@fields,\@col_ids);
	@ordered_fields = (@fields,@ordered_fields);

	# Special case... can't remembet why we need this
	if(!$self->match_any(@fields,'ticket')){
		push(@fields,'ticket');
	}

	for(my $i=0;$i<@col_ids;$i++){
		my $label = $col_ids[$i];
		my $info = $self->get_the_damn_field($label);

		push(@select,$info->{'name'});
		push(@as,$info->{'label'});

		push(@order,$info->{'sort'});

		# if we have to join to another table to get this column...
		if($info->{'join'}){
			# join_type is the type of join: left, right, inner, etc.
			push(@join_type,$info->{'join'}->{'type'});

			# join_on is the table to join onto. Should have called 
			# this 'table' because 'test' below is really the 'on' 
			# part of the SQL statement
			push(@join_on,$info->{'join'}->{'on'});

			# join_test is the comparison that must be made (the 
			# test) to determine whether to join a given record
			push(@join_test,'('.($info->{'join'}->{'from'}).' '.($info->{'join'}->{'compare'}).' '.($info->{'join'}->{'to'}).')');
		}

	}

	# Build where/and info from form value submit. 
	for(my $i=0;$i<@values;$i++){
		if($values[$i] ne ''){
			my $info = $self->get_the_damn_field($fields[$i]);
			my $p = $cmp{$comparison[$i]}->{'pattern'};
			my $where = $info->{'where'}.' ';

			# Special case for 'between'. Doesn't really work...
			if($cmp{$comparison[$i]}->{'sql'} eq 'between'){
				my ($b1,$b2) = split(/ and /,$values[$i]);
				if(defined($b1) && defined($b2) && $b1 ne '' && $b2 ne ''){
					$p =~ s/\*/$b1/;
					$p =~ s/\*/$b2/;
					$where .= $cmp{$comparison[$i]}->{'sql'}.' '.$self->param('hddb')->quote($b1).' and '.$self->param('hddb')->quote($b2);
				} else{
					# Malformed values! Skip this.
					warn "Report: Encountered malformed 'between' request '$values[$i]'\n";
					next;
				}
			} else{
				# This is where all of that comparison mumbo-jumbo finally pays off.
				$p =~ s/\*/$values[$i]/;
				$where .= $cmp{$comparison[$i]}->{'sql'}.' '.$self->param('hddb')->quote($p);
			}
			push(@where,$where);
			push(@and,$andor[$i]);
		}
	}

	# select all of the fields as their As value specified in the .rmap file
	# Currently As is not seen by the user but this helps ensure uniqueness.
	for(my $i=0;$i<@select;$i++){
		$select[$i] .= ' as '.$self->param('hddb')->quote($as[$i]);
	}

	# What does this do any more?
	foreach my $f (@{$self->param('report')->{'fields'}}){
		my $k = keys %{$f};
	}

	# Done with 'select' portion of SQL.
	my $select = join(', ', @select);

	# On to the 'join' portion...
	my @join;
	for(my $i=0;$i<@join_type;$i++){
		push(@join, $join_type[$i].' join '.$join_on[$i].' on '.$join_test[$i]);
	}
	my $join = join(' ',@join);

	my $where = $self->group_by_consecutive('or',\@and,\@where);

	my @sorted_no_empties;
	foreach my $s (@sort){
		if($s ne ''){
			my $info = $self->get_the_damn_field($s);
#die Data::Dumper::Dumper $s if !$info->{'sort'};
			$s = $info->{'sort'};
			push(@sorted_no_empties,$s);
		}
	}
#	@order = $self->uniq(@sort,@order);
#	@order = @sort;

	my $order = join(', ', @sorted_no_empties);
	if(!@where){ # If we have no WHERE clause something has gone horribly wrong.
		warn 'Report: No where clause when making SQL?';
		$self->param('stash')->{'sql'} = '';
#		return '';
	} else{
		my $table = $self->param('report')->{'primarytable'};
		my $sql = "select $select from $table $join where $where ".($order?"order by $order":"").";";
		$self->param('stash')->{'sql'} = $sql;
#		return $sql;
	}
}

# Spits out a string of @where's joined together with @and's. If there
# are consecutive 'or' values in @and's it puts parentheses around the 
# the @where and @and in the output.
# e.g.:
# @where: this = 'foo' ; that = 'bar' ; other = 'baz' ; whatever = 'qux' ; any = 'quux'
# @and: and ; and ; or ; or ; and
# returns:
# this = 'foo' and that = 'bar' or (other = 'baz' or whatever = 'qux') and any = 'quux'
sub group_by_consecutive{
	my $self = shift;
	my $consec = shift;
	my $keys = shift;
	my $vals = shift;

	my @andwhere; # andwhere is to contain WHERE clauses with the correct ANDOR suffix (or none if last)
	my $or_flag = 0;

	for(my $w=0;$w<@{$vals};$w++){
		# Primitive grouping of consecutive OR statements. Seems to do the expected in common cases.
		if($w != 0){
			if(@{$keys}[$w - 1] eq 'or' && defined(@{$vals}[$w+1])){
				if($or_flag == 0){
					$andwhere[$w - 1] = '('.$andwhere[$w - 1];
					$or_flag = 1;
				}
			} else{
				if($or_flag == 1){
					$andwhere[$w - 1] .= ')';
					$or_flag = 0;
				}
			}
			$andwhere[$w - 1] .= ' '.@{$keys}[$w - 1];
		}
		push(@andwhere,@{$vals}[$w]);
	}
	my $where = join(' ',@andwhere);
	# If the last statement was an OR, close the group with )
	if($or_flag == 1){
		$where .= ')';
		$or_flag = 0;
	}
	return $where;
}

# pass it \@fields,\@columns
# returns all elements of columns that do not appear in fields
sub all_not_in{
	my $self = shift;
	my $flds = shift;
	my $cols = shift;
	my @notin;
	foreach my $v (@{$cols}){
		if(!$self->match_any(@$flds,$v)){
			push (@notin,$v);
		}
	}
	return @notin;
}

# Load the SQL comparision information from YAML
sub get_cmps{
	my $self = shift;

        my $ops = YAML::LoadFile($self->param('config')->{'config_dir'}.'/'.$self->param('config')->{'comparisons'});

	my %cmp;
        my @ops = @{$ops->{'comparisons'}};

	return @ops;
}

# $self->selectoryify(\@labels,\@values,'label of default selection');
sub selectorify{
	my $self = shift;
	my $ar_labels = shift;
	my $ar_values = shift;
	my $match = shift;
	my @loop;
	my %h;
	for(my $i=0;$i<@{$ar_labels};$i++){
		my $selected = '';
		if($ar_values->[$i] eq $match){
			$selected = ' selected';
		}
		push(@loop,{
			'txt' => $ar_labels->[$i],
			'val' => $ar_values->[$i],
			'selected' => $selected,
		});
	}

	return @loop;
}

1;
