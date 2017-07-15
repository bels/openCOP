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
	my ($self,$firstname,$lastname,$password,$username,$activate) = @_;
	
	my $rs = $self->pg->db->query('select * from auth.register(?,?,?,?)',$firstname,$lastname,$password,$username)->hash;

	if($rs->{'status'} == SUCCESS){
		if($activate == 1){
			my $result = $self->pg->db->query('select * from platform.create_token(?,?)',$rs->{'id'},'activation')->hash;
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

sub full_name{
	my ($self,$user_id) = @_;

	my $name = $self->pg->db->query("select first || ' ' || last as name from users where id = ?",$user_id)->hash;
	
	return $name->{'name'};
}

sub get_profile_data{
	my ($self,$user_id,$data_type) = @_;
	
my $with_data_type =<<SQL;
select
	content,
	default_primary
from 
	profile
where user_id = ? and data_type = (select id from profile_data_type where description = ?) and active = true
SQL
my $without_data_type =<<SQL;
select
	p.content,
	p.default_primary,
	pdt.description
from
	profile p
join
	profile_data_type pdt
on
	p.data_type = pdt.id
SQL
	if(defined($data_type)){
		return $self->pg->db->query($with_data_type,$user_id,$data_type)->hashes->to_array;
	} else {
		return $self->pg->db->query('select content, from profile where user_id = ? and active = true',$user_id)->hashes->to_array;
	}
}

sub account_type{
	my $self = shift;
	#pass in id, then account type
	my ($id,$type) = (undef,undef);
	if(@_){
		($id,$type) = @_;
		$self->pg->db->query("select * from update_profile(?,'account_type',?)",$id,$type);
	}
	
	return $self->pg->db->query("select content from profile where data_type = (select id from profile_data_type where description = 'account_type') and user_id = ?",$id)->hash;
}

sub site{
	my $self = shift;
	
	my ($id,$site) = (undef,undef);
	if(@_){
		($id,$site) = @_;
		$self->pg->db->query('update users set site = ? where id = ?',$site,$id);
	}
	
	return $self->pg->db->query('select site from users where id = ?',$id)->hash->{'site'};
}
1;