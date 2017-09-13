package Opencop::Controller::Admin;
use Mojo::Base 'Mojolicious::Controller';

sub new_user{
	my $self = shift;
	
	my $rv = $self->account->create($self->param('firstname'),$self->param('lastname'),$self->param('password1'),$self->param('username'),0,$self->param('account_type'));
	if($rv->{'status'} == 1){
		my $id = $rv->{'id'};
		unless($self->param('site') eq ''){
			$self->account->site($id,$self->param('site'));
		}
	}
	#TODO add error messages to the front end and handle error cases
	$self->redirect_to($self->url_for('admin_dashboard'));
}

sub dashboard{
	my $self = shift;
	
	my $site_list = [['No Site' => '']];
	my $sl = $self->ticket->site_list;
	foreach my $row (@{$sl}){
		push(@{$site_list},$row);
	}
	$self->stash(
		sites => $site_list,
		account_type_list => $self->account->type_list
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