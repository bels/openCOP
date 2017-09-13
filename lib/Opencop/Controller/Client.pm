package Opencop::Controller::Client;
use Mojo::Base 'Mojolicious::Controller';

sub dashboard{
	my $self = shift;

	$self->stash(
		js => ['https://cdn.datatables.net/v/bs/jqc-1.12.4/dt-1.10.15/cr-1.3.3/datatables.min.js','/js/common/require.js','/js/private/client.js'],
		styles => ['https://cdn.datatables.net/v/bs/jqc-1.12.4/dt-1.10.15/cr-1.3.3/datatables.min.css','/styles/private/queue.css'],
		status_list => $self->ticket->status_list($self->session('user_id')),
		sections => []
	);
}

sub index{
	my $self = shift;
}
1;