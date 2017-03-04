package Opencop::Model::Account;
use Mojo::Base -base;

has 'pg';
has 'debug';

use constant {
	SUCCESS => 1,
	FAILED_CREATE_USER => -1,
	FAILED_PROFILE_DATA => -2,
	FAILED_DELETE_USER => -3
};

sub create{
	my ($self,$name,$password,$email,$activate) = @_;
	
	my $rs = $self->pg->db->query('select * from auth.register(?,?,?)',$name,$password,$email)->hash;

	if($rs->{'status'} == SUCCESS){
		if($activate == 1){
			my $result = $self->pg->db->query('select * from platform.create_token(?,?)',$name,'activation')->hash;
			if($result->{'status'} == 1){
				$rs->{'token'} = $result->{'token'};
			}
		} else{
			my $result = $self->pg->db->query('update auth.users set active = true where id = ?',$rs->{'id'});
		}
	}

	return $rs;
}

sub delete{
	
}

sub edit{
	
}

1;