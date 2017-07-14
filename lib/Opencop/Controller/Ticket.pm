package Opencop::Controller::Ticket;
use Mojo::Base 'Mojolicious::Controller';

sub new_form{
	my $self = shift;

	
	$self->stash(
		js => [
			'/js/common/jquery/plugins/jquery.validate.min.js',
			'/js/common/jquery/plugins/additional-methods.min.js',
			'/js/common/moment.js',
			'/js/common/bootstrap-datetimepicker.min.js',
			'/js/private/new_ticket.js',
		],
		styles => [
			'/styles/common/bootstrap-datetimepicker.css'
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

	unless($self->session('csrf_token') eq $self->param('csrf_token')){
		$self->render(json => {message => 'CSRF Token Bad'}, status => 403);
		return;
	}
	warn $self->dumper($self->req->params->to_hash,$self->session->{'user_id'}) if $self->app->mode eq 'development';
	$self->ticket->new_ticket($self->req->params->to_hash,$self->session->{'user_id'});
	$self->redirect_to($self->url_for('new_ticket_form'));
}

sub view_ticket{
	my $self = shift;

	my $ticket = $self->ticket->get_ticket($self->param('ticket_id'));
	#we need to set what is selected so the technician doesn't need to change it each time
	my $sites = $self->ticket->site_list;
	my $priorities = $self->ticket->priority_list;
	my $sections = $self->ticket->section_list;
	my $technicians = $self->ticket->technician_list;
	my $statuses = $self->ticket->status_list;

	$self->stash(
		js => [
			'/js/common/jquery/plugins/jquery.validate.min.js',
			'/js/common/jquery/plugins/additional-methods.min.js',
			'/js/common/moment.js',
			'/js/common/bootstrap-datetimepicker.min.js',
			'/js/private/new_ticket.js',
			'/js/private/ticket.js',
		],
		styles => [
			'/styles/common/bootstrap-datetimepicker.css'
		],
		company_name => $self->config->{'company_name'},
		sites => $self->set_selected($sites,1,$ticket->{'site'}),
		author => $self->account->full_name($self->session('user_id')),
		priorities => $self->set_selected($priorities,1,$ticket->{'priority'}),
		sections => $self->set_selected($sections,1,$ticket->{'section'}),
		technicians => $self->set_selected($technicians,1,$ticket->{'technician'}),
		ticket => $ticket,
		troubleshooting => $self->ticket->get_troubleshooting($self->param('ticket_id')),
		statuses => $self->set_selected($statuses,1,$ticket->{'status'})
	);
}

sub update{
	my $self = shift;
	my $data = $self->req->json;

	unless($self->session('csrf_token') eq $data->{'csrf_token'}){
		$self->render(json => {message => 'CSRF Token Bad'}, status => 403);
		return;
	}
	
	$self->ticket->update_ticket($self->session('user_id'),$data);
	$self->render(json => {status => Mojo::JSON->true, message => 'Submitted'}, status => 200);
}

sub add_troubleshooting{
	my $self = shift;

	$self->ticket->add_troubleshooting($self->session('user_id'),$self->req->params->to_hash);
	
	$self->render(json => {message => 'Add Troubleshooting', success => Mojo::JSON->true},status => 200);
}
1;