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

sub new_customer{
	my $self = shift;
}

sub edit_customer{
	my $self = shift;
}

sub customer_dashboard{
	my $self = shift;
}

sub delete_customer{
	my $self = shift;
}

sub new_site{
	my $self = shift;
}

sub edit_site{
	my $self = shift;
}

sub delete_site{
	my $self = shift;
}
1;