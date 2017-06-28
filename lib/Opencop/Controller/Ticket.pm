package Opencop::Controller::Ticket;
use Mojo::Base 'Mojolicious::Controller';

sub new_form{
	my $self = shift;

	
	$self->stash(
		company_name => $self->config->{'company_name'},
		sites => $self->ticket->site_list,
		author => $self->account->full_name($self->session('user_id')),
		priorities => $self->ticket->priority_list,
		sections => $self->ticket->section_list,
		technicians => $self->ticket->technician_list
	);
}

1;