package Opencop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub new_user{
	
}

sub dashboard{
	my $self = shift;
	
	$self->stash(
		sites => $self->ticket->site_list
	);
}
1;