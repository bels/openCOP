#!/usr/bin/perl

package CCBOEHD::template;
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
		filename => 'default.html',
		path => [
			'/home/collin/src/CCBOE/app/HTML::Template/templates',
			'/home/collin/src/CCBOE/app/templates',
		],
	));
	
	$self->start_mode('default');
	$self->mode_param('mode');
	$self->run_modes(
		'default' => 'default_sub',
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

sub default_sub{
	my $self = shift;
	return $self->hddb_print();
}


## 
## Internal functions
## 

1;
