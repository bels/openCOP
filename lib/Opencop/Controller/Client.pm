package Opencop::Controller::Client;
use Mojo::Base 'Mojolicious::Controller';

sub dashboard{
	my $self = shift;
	
	$self->res->headers->header('X-Frame-Options' => 'ALLOW-FROM https://chat2.infinity-ts.com:3002/livechat');
	$self->stash(
		js => ['/js/common/require.js']
	);
}

sub index{
	my $self = shift;
}
1;