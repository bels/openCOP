package Opencop::Model::Ticket;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub new_ticket{
	my ($self,$data,$submitter_id) = @_;
warn $submitter_id;
my $sql =<<SQL;
insert into ticket(
	status,
	barcode,
	site,
	location,
	author,
	contact,
	contact_phone,
	section,
	synopsis,
	problem,
	priority,
	serial,
	contact_email,
	technician,
	submitter,
	availability_time)
values
	(
	(select id from status where status = 'New'),
	?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
	)
returning id
SQL
	my $ticket = $self->pg->db->query($sql,
		$data->{'barcode'},
		$data->{'site'},
		$data->{'location'},
		$data->{'author'},
		$data->{'contact'},
		$data->{'phone'},
		$data->{'section'},
		$data->{'synopsis'},
		$data->{'problem'},
		$data->{'priority'},
		$data->{'serial'},
		$data->{'email'},
		$data->{'tech'},
		$submitter_id,
		$data->{'availability_time'}
	)->hash;
	
	return $ticket->{'id'};
}

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

sub queue_overview{
	my ($self,$tech_id) = @_;

my $sql =<<SQL;
select
	t.id,
	t.ticket,
	t.synopsis,
	u.first || ' ' || u.last as technician,
	s.status,
	se.name as section,
	t.genesis
from
	ticket t
join
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
where
	t.section in (select section from technician_section where technician = ?)
and
	t.technician = ?
SQL
	#grab all tickets for technician
	my $tickets = $self->pg->db->query($sql,$tech_id,$tech_id)->hashes->to_array;
	
	#organize tickets into sections
	my $queues = {};
	foreach my $ticket (@{$tickets}){
		$queues->{$ticket->{'section'}} = [] unless exists($queues->{$ticket->{'section'}});

		push(@{$queues->{$ticket->{'section'}}},$ticket);	
	}

	return $queues;
}

sub get_ticket{
	my ($self,$id) = @_;

my $sql =<<SQL;
select
	t.id,
	t.genesis,
	t.site,
	si.name as site_name,
	t.synopsis,
	t.author,
	t.barcode,
	t.serial,
	t.contact,
	t.contact_phone,
	t.location,
	t.priority,
	p.severity || ' - ' || p.description priority_name,
	t.section,
	se.name as section,
	t.technician,
	u.first || ' ' || u.last as tech_name,
	t.problem,
	s.status
from
	ticket t
join
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
join
	priority p
on
	t.priority = p.id
join
	site si
on
	t.site = si.id
where
	t.id = ?
SQL

	return $self->pg->db->query($sql,$id)->hash;
}
1;