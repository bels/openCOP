package Opencop::Model::Ticket;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub site_list{
	my $self = shift;
	
	return $self->pg->db->query("select c.name || ' - ' || s.name as name,s.id from site s join company c on s.company_id = c.id")->arrays->to_array;
}

sub priority_list{
	my $self = shift;

my $sql =<<SQL;
select
	severity::TEXT || ' - ' || description as name,
	id
from
	priority
SQL
	return $self->pg->db->query($sql)->arrays->to_array;
}

sub section_list{
	my $self = shift;
	
my $sql =<<SQL;
select
	name,
	id
from
	section
SQL
	return $self->pg->db->query($sql)->arrays->to_array;
}

sub technician_list{
	my $self = shift;
	
my $sql =<<SQL;
select
	u.first || ' ' || u.last as name,
	u.id
from
	users u
join
	profile p
on
	u.id = p.user_id
where
	p.content = 'technician'
and
	p.data_type = (select id from profile_data_type where description = 'account_type')
SQL

	return $self->pg->db->query($sql)->arrays->to_array;
}
1;