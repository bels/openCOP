#!/usr/bin/perl




package CCBOEHD::Ticket;
use base qw(CCBOEHD::Base);


use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;


our %field_to_temmplate_param = (
	'ticket' => 'helpdesk_ticket',
	'barcode' => 'helpdesk_barcode',
	'requested' => 'helpdesk_requested',
	'updated' => 'helpdesk_updated',
	'author' => 'helpdesk_author',
	'contact' => 'helpdesk_contact',
	'contact_phone' => 'helpdesk_phone',
	'tech' => 'helpdesk_tech',
	'problem' => 'helpdesk_problem',
	'troubleshot' => 'helpdesk_troubleshot',
	'notes' => 'helpdesk_notes',
	'location' => 'helpdesk_location',

	'status' => 'helpdesk_status_loop',
	'priority' => 'helpdesk_priority_loop',
	'section' => 'helpdesk_section_loop',
	'school' => 'helpdesk_school_loop',
);



##
## Overrides
##

sub setup
{
	my $self = shift;
	
	$self->param('template' => HTML::Template->new(
		filename => 'edit-ticket.html',
		path => [
			'/home/collin/src/CCBOE/app/HTML--Template/templates',
			'/home/collin/src/CCBOE/app/templates',
		],
	));

	$self->start_mode('newt');
	$self->mode_param('mode');
	$self->run_modes(
		'view' => 'edit_ticket',
		'newt' => 'new_ticket',
		'update' => 'update_existing_ticket',
		'add' => 'add_new_ticket',
	);
	$self->db_connect;
}

sub hddb_print
{
	my $self = shift;
	# Load template, perform substitutions...
	my $html = "<html><body>\n";
	$html .= join('',@_) if @_;
	$html .= "</body></html>";
	return $html;
}


## 
## Interface functions
## 

sub edit_ticket{
	my $self = shift;

	$self->param('template')->param('submit_mode' => 'update');
	$self->param('template')->param('submit_text' => 'Update');

	$self->param('template')->param('edit_mode' => 1);

	$self->populate_edit_fields(1);

	return $self->param('template')->output();
}

sub new_ticket{
	my $self = shift;

#	$self->param('template')->param('submit_mode' => 'insert');
#	$self->param('template')->param('submit_text' => 'Submit request');

#	$self->populate_edit_fields(1);

	return $self->param('template')->output();
}

sub whatever{
	my $self = shift;

	my %form = $self->form_to_variables();
	
	
}


# & is the contents of the variable. 'condition' will evaluate to true for valid data when its value is evaluated
#my @check = (
#	{
#		'form_field' => 'barcode',
#		'table_field' => 'barcode',
#		'condition' => 'defined(&)',
#		
#	},
#	{
#		'form_field' => 'author',
#		'table_field' => 'author',
#		'condition' => 'defined(&)',
#		
#	},
#	{
#		'form_field' => 'school',
#		'table_field' => 'barcode',
#		'condition' => '& != -1',
#		
#	},
#
#	
#);

## 
## Internal functions
## 

sub populate_edit_fields{
	my $self = shift;
	my $ticket = shift;
	my $sth = $self->param('hddb')->prepare("select status, priority, barcode, serial, school, location, requested, updated, author, contact, contact_phone, troubleshot, notes, team, section, problem from helpdesk where ticket = $ticket;");
	$sth->execute();

	my ($status, $priority, $barcode, $serial, $school, $location, $requested, $updated, $author, $contact, $contact_phone, $troubleshooting, $notes, $team, $section, $problem) = $sth->fetchrow_array();
	$self->param('template')->param('status_select' => $self->ticket_status_selector($status));
	$self->param('template')->param('priority_select' => $self->priority_selector($priority)); # Only a tech can set priority
	$self->param('template')->param('school_select_field' => $self->school_selector($school, 'name'));


	if($barcode && $serial){
		# Do nothing
	} elsif($barcode){
		$serial = $self->lookup('serial','inventory','barcode',$barcode);
	} elsif($serial){
		$barcode = $self->lookup('barcode','inventory','serial',$serial);
	} else{
		$barcode = "";
		$serial = "";
	}



	# This stuff wont work yet.
	$self->param('template')->param('requested' => $updated);
	$self->param('template')->param('updated' => $requested);
	$self->param('template')->param('ticket' => $ticket);
	$self->param('template')->param('notes' => $notes);
	$self->param('template')->param('barcode' => $barcode);
	$self->param('template')->param('author' => $author);
	$self->param('template')->param('contact' => $contact);
	$self->param('template')->param('phone' => $contact_phone);
	$self->param('template')->param('location' => $location);
	$self->param('template')->param('problem' => $problem);
	$self->param('template')->param('troubleshooting' => $troubleshooting);

}

sub lookup{
	my $self = shift;
	my $field = shift;
	my $table = shift;
	my $checkfield = shift;
	my $value = shift;

	my $sth = $self->param('hddb')->prepare("select $field from $table where $checkfield = '$value';");
	$sth->execute();
	return $sth->fetchrow_array();
}

sub populate_new_fields{
	my $self = shift;
	my $ticket = shift;

	$self->param('template')->param('school_select_field' => $self->school_selector($self->school_from_ip(), 'name'));

}

sub populate_common_fields{
	my $self = shift;
	my $ticket = shift;
	my $sth = $self->param('hddb')->prepare("select status, priority, barcode, school, location, requested, updated, author, contact, contact_phone, troubleshot, notes, team, section, problem from helpdesk where ticket = $ticket;");
	$sth->execute();

	my ($status, $priority, $barcode, $school, $location, $requested, $updated, $author, $contact, $contact_phone, $troubleshooting, $notes, $team, $section, $problem) = $sth->fetchrow_array();
#	$self->param('template')->param('' => );

	return 1;
}

sub ticket_status_selector{
        my $self = shift;
        my $selected = shift;
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = 1;
        }
        my $sth = $self->param('hddb')->prepare("select tsid,name from ticket_status order by tsid;");
        $sth->execute();

        my $select = '';
        while(my ($tsid,$status) = $sth->fetchrow_array()){
                if($tsid == $selected){
                        $select .= qq(<option value="$tsid" selected="true">$status</option>\n);
                } else{
                        $select .= qq(<option value="$tsid">$status</option>\n);
                }
        }
        return $select;
}

sub priority_selector{
        my $self = shift;
        my $selected = shift;
        if(defined($selected)){
                $selected = $selected;
        } else{
                $selected = 3;
        }
        my $sth = $self->param('hddb')->prepare("select prid,description from priority order by severity;");
        $sth->execute();

        my $select = '';
        while(my ($prid,$desc) = $sth->fetchrow_array()){
                if($prid == $selected){
                        $select .= qq(<option value="$prid" selected="true">$desc</option>\n);
                } else{
                        $select .= qq(<option value="$prid">$desc</option>\n);
                }
        }
        return $select;
}

sub school_selector{
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

        my $select = '';
        while(my ($scid,$name) = $sth->fetchrow_array()){
                if($scid == $selected){
                        $select .= qq(<option value="$scid" selected="true">$name</option>\n);
                } else{
                        $select .= qq(<option value="$scid">$name</option>\n);
                }
        }
        return $select;
}


sub fill_by_barcode{
	my $self = shift;

	my $barcode = shift;
	my @fieldnames = $self->columns_of('helpdesk');

	my $h = $self->param('hddb')->prepare(
		qq(select * from helpdesk where barcode = ).$self->param('hddb')->quote($barcode).qq(;)
	);
	$h->execute();
	my $data = $h->fetchrow_hashref;

	foreach my $item (@fieldnames){
#		if($field_to_template_param{$item}){
#			$self->param('template')->param($field_to_template_param{$item} => $data->{$item});
#		}
	}
}

1;


__END__


