package Opencop::Controller::User;
use Mojo::Base 'Mojolicious::Controller';

sub preferences{
	my $self = shift;
	
	$self->stash(
		js => ['/js/private/user.js'] 
	);
}

sub set_password{
	my $self = shift;
	
	if($self->param('password1') eq $self->param('password2')){
		$self->account->set_password($self->session('user_id'),$self->param('password1'));
		$self->flash(success => 1, message => 'Successfully set your password');
	} else {
		$self->flash(success => 0, message => 'Passwords did not match.  Try again.');
	}
	
	$self->redirect_to($self->url_for('user_preferences'));
}
1;