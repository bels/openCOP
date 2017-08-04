package Opencop::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

#authenticates a user and creates their session cookie
sub authenticate{
	my $self = shift;
	
	my $session = $self->session->{'id'} // '00000000-0000-0000-0000-000000000000';
	if($self->auth->verifySession($session)){
		#checking what we have in the database vs what is in the cookie if there is one
		#if there is no cookie for this domain, create one
		my $session = $self->auth->retrieveSessionByID($session);
		$self->redirect_to($self->url_for($self->config->{'landing_page'}));
	}
	my $username = $self->param('username') // '';
	my $password = $self->param('password') // '';
	my $address = $self->tx->remote_address // 'Could not get ip. Something is wrong!';
	warn sprintf('username: %s password: %s address: %s',$username,$password , $address) if $self->app->mode eq 'development';
	my $session_info = $self->auth->authenticate($username,$password,$address);

	if($session_info->{'status'} == Opencop::Model::Auth::SUCCESSFUL_LOGIN || $session_info->{'status'} == Opencop::Model::Auth::ALREADY_AUTHED){
		$self->session($session_info->{'session'});
		if($self->tx->req->is_xhr){
			$self->render(json => {success => Mojo::JSON->true}) and return;	
		}
		$self->redirect_to($self->flash('destination')) and return if defined $self->flash('destination');
		
		if($self->session('account_type') eq 'Technician'){
			$self->redirect_to($self->url_for($self->config->{'technician_landing_page'}));
		} else {
			$self->redirect_to($self->url_for($self->config->{'customer_landing_page'}));
		}
		return;
	} else {
		if($session_info->{'status'} == Opencop::Model::Auth::ACCOUNT_LOCKED){
			$self->flash(login_error => 'You have failed login 3 times. Please wait 10 minutes before trying again. This is to help protect your security.');
			$self->redirect_to($self->url_for('index'));
		}
		if($self->tx->req->is_xhr){
			$self->render(json => {success => Mojo::JSON->false})
		} else {
			if($session_info->{'status'} == Opencop::Model::Auth::BAD_PASSWORD){
				$self->flash(login_error => 'Bad username/password');
			}
			if($session_info->{'status'} == Opencop::Model::Auth::BAD_USERNAME){
				#i know this is redundant but in case we want to give a different error message later we can
				$self->flash(login_error => 'Bad username/password');
			}
			$self->redirect_to($self->url_for('index'));
		}
		return;
	}
}

#used by mojolicious to see if someone has an active session before being allowed to access a page
sub check_session {
	my $self = shift;

	my $session = $self->session->{'id'} // '00000000-0000-0000-0000-000000000000';
	if($self->auth->verifySession($session)){
		$self->auth->refreshSession($session);
		return 1;
	}
	$self->flash(error => 'You tried to access a resource that requires you to be logged in.  Please login to continue.');
	if($self->tx->req->is_xhr){
		$self->render(json => {status => Mojo::JSON->false}, status => 403);
	} else {
		$self->redirect_to($self->url_for('index'));
	}
	return;
}

sub logout{
	my $self = shift;
	
	$self->auth->logout($self->session('id'));
	$self->session(expires => 1);
	$self->redirect_to($self->url_for('index'));
}
1;