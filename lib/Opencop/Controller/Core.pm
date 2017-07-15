package Opencop::Controller::Core;
use Mojo::Base 'Mojolicious::Controller';


sub index {
	my $self = shift;

	my $session = $self->session->{'id'} // '00000000-0000-0000-0000-000000000000';
	if($self->auth->verifySession($session)){
		$self->redirect_to($self->flash('destination')) and return if defined $self->flash('destination');
		$self->redirect_to($self->config('technician_landing_page')) and return;
	}
}

sub dashboard{
	my $self = shift;
}
1;
