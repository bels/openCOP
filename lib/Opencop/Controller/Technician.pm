package Opencop::Controller::Technician;
use Mojo::Base 'Mojolicious::Controller';

sub dashboard{
	my $self = shift;

	$self->res->headers->cache_control('no-store');
	$self->stash(
		js => ['https://cdn.datatables.net/v/bs/jqc-1.12.4/dt-1.10.15/cr-1.3.3/datatables.min.js','/js/private/queue.js'],
		styles => ['https://cdn.datatables.net/v/bs/jqc-1.12.4/dt-1.10.15/cr-1.3.3/datatables.min.css','/styles/private/technician_dashboard.css','/styles/private/queue.css'],
		sections => $self->core->section_list,
		status_list => $self->ticket->status_list($self->session('user_id'))
		#queues => $self->ticket->queue_overview($self->session('user_id'))
	);
}
1;