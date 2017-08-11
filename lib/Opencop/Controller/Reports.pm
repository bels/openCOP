package Opencop::Controller::Reports;
use Mojo::Base 'Mojolicious::Controller';

sub view_all{
	my $self = shift;

	$self->stash(
		reports => $self->reports->list_all
	);
}

sub view{
	my $self = shift;

	$self->stash(
		current_report => $self->param('report')
	);
}

sub retrieve_report{
	my $self = shift;
}
1;