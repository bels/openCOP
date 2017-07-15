package Opencop::Model::Core;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub company_list{
	my $self = shift;
	
	return $self->pg->db->query("select name,id from company order by name asc")->arrays->to_array;
}

sub site_level_list{
	my $self = shift;
	
	return $self->pg->db->query("select type,id from site_level order by type asc")->arrays->to_array;
}

sub new_customer{
	my ($self,$name) = @_;
	
	my $id = $self->pg->db->query('insert into company(name) values (?) returning id',$name)->hash;
	return $id->{'id'}; 
}

sub new_site{
	my ($self,$data) = @_;

	my $id = $self->pg->db->query('insert into site(name,street,city,state,zip,company_id,level) values (?,?,?,?,?,?,?) returning id',
		$data->{'name'},$data->{'street'},$data->{'city'},$data->{'state'},$data->{'zip'},$data->{'company'},$data->{'level'}
		)->hash;
	return $id->{'id'};
}

sub section_list{
	my $self = shift;
	
	return $self->pg->db->query('select name,id from section order by name asc')->arrays->to_array;
}
1;