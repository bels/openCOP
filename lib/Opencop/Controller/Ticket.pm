package Opencop::Controller::Ticket;
use Mojo::Base 'Mojolicious::Controller';

sub new_form{
	my $self = shift;

	
	$self->stash(
		js => [
			'/js/common/jquery/plugins/jquery.validate.min.js',
			'/js/common/jquery/plugins/additional-methods.min.js',
			'/js/private/new_ticket.js',
		],
		company_name => $self->config->{'company_name'},
		sites => $self->ticket->site_list,
		author => $self->account->full_name($self->session('user_id')),
		priorities => $self->ticket->priority_list,
		sections => $self->ticket->section_list,
		technicians => $self->ticket->technician_list
	);
}

sub new_ticket{
	my $self = shift;

	warn $self->dumper($self->req->params->to_hash,$self->session->{'user_id'}) if $self->app->mode eq 'development';
	$self->ticket->new_ticket($self->req->params->to_hash,$self->session->{'user_id'});
	$self->redirect_to($self->url_for('new_ticket_form'));
}

1;