package Opencop::Model::Queues;
use Mojo::Base -base;

use UUID::Tiny ':std';

has 'pg';
has 'debug';

sub queues_available_to_user{
	my ($self,$user) = @_;
	
	return $self->pg->db->query('select section from technician_section where technician = ?',$user)->array;
}

sub get_queue{
	my ($self,$queue,$statuses) = @_;

	my $status_array = '';
	if(ref $statuses eq 'ARRAY'){
		if(is_uuid_string($statuses->[0])){
			#looks like list of uuids
			$status_array = join("'::UUID,'",@{$statuses});
		} else {
			#I am assuming you used the status_list function in the ticket model to pass in the status list here
			foreach my $row (@{$statuses}){
				$status_array .=  "'" . $row->[1] . "'::UUID,"; 
			}
			chop($status_array);
		}
	} else {
		#looks like you passed in a single UUID?
		if(is_uuid_string($statuses)){
			$status_array = "ARRAY['$statuses']";
		} else {
			#we don't want this to error so we're just putting a empty uuid here
			$status_array = 'ARRAY[' . create_uuid(UUID_NIL) . ']';
		}
	}

my $sql =<<SQL;
select
	t.id,
	t.ticket,
	t.contact,
	c.name as company,
	t.synopsis,
	u.first || ' ' || u.last as technician,
	s.status,
	se.name as section,
	t.genesis
from
	ticket t
left join
	users u
on
	t.technician = u.id
join
	status s
on
	t.status = s.id
join
	section se
on
	t.section = se.id
left join
	site
on
	t.site = site.id
left join
	company c
on
	site.company_id = c.id
where
	t.active = true
and
	t.section = ?
and
	s.id in ($status_array)
order by
	t.genesis desc
SQL

	warn $queue;
	return $self->pg->db->query($sql,$queue)->arrays->to_array;
}

1;