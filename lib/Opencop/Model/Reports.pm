package Opencop::Model::Reports;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub list_all{
	my $self = shift;

	return $self->pg->db->query('select name,report from reports where active = true order by name desc')->arrays->to_array;
}

1;