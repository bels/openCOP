package Opencop::Model::Queues;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub queues_available_to_user{
	
}

sub get_queue{
	my ($self,$queue,$statuses) = @_;

	
}

1;