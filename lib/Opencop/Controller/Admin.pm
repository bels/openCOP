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

sub general_settings{
	my $self = shift;

}

sub new_customer{
	my $self = shift;
	
	unless($self->session('csrf_token') eq $self->param('csrf_token')){
		#TODO add error message later
		$self->redirect_to($self->req->headers->referrer);
		return;
	}
	$self->core->new_customer($self->param('name'));
	$self->redirect_to($self->req->headers->referrer);
}

sub edit_customer{
	my $self = shift;
}

sub customer_settings{
	my $self = shift;
	
	$self->stash(
		companies => $self->core->company_list,
		levels => $self->core->site_level_list
	);
}

sub delete_customer{
	my $self = shift;
}

sub new_site{
	my $self = shift;
	
	unless($self->session('csrf_token') eq $self->param('csrf_token')){
		#TODO add error message later
		$self->redirect_to($self->req->headers->referrer);
		return;
	}
	$self->core->new_site($self->req->params->to_hash);
	$self->redirect_to($self->req->headers->referrer);
}

sub edit_site{
	my $self = shift;
}

sub delete_site{
	my $self = shift;
}
1;