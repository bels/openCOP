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
	my $availability_time = $data->{'availability_time'} ne '' ? $data->{'availability_time'} : undef;
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
		$availability_time
	)->hash;

	$self->_insert_troubleshooting($submitter_id,$ticket->{'id'},$data->{'troubleshoot'});
	$self->_add_history($ticket->{'id'},'create','new',$submitter_id,undef,undef);
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
where
	active = true
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

sub status_list{
	my $self = shift;

my $sql =<<SQL;
select
	status,
	id
from
	status
where
	active = true
SQL
	return $self->pg->db->query($sql)->arrays->to_array;
}
sub queue_overview{
	my ($self,$tech_id) = @_;

my $sql =<<SQL;
select
	t.id,
	t.ticket,
	t.contact,
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
	t.ticket,
	si.name as site_name,
	t.synopsis,
	t.author,
	t.barcode,
	t.serial,
	t.contact,
	t.contact_phone,
	t.contact_email,
	t.location,
	t.priority,
	p.severity || ' - ' || p.description priority_name,
	t.section,
	se.name as section,
	t.technician,
	u.first || ' ' || u.last as tech_name,
	t.problem,
	s.status,
	t.availability_time
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

sub get_troubleshooting{
	my ($self,$ticket_id) = @_;
	
my $sql =<<SQL;
select
	u.first || ' ' || u.last as tech_name,
	t.troubleshooting,
	t.genesis
from
	troubleshooting t
join
	users u
on
	t.technician = u.id
where
	ticket = ?
SQL

	return $self->pg->db->query($sql,$ticket_id)->hashes->to_array;
}

sub update_ticket{
	my ($self,$data) = @_;

my $sql =<<SQL;
update ticket set
	site = ?,
	status = ?,
	barcode = ?,
	serial = ?,
	author = ?,
	location = ?,
	contact = ?,
	contact_phone = ?,
	contact_email = ?,
	section = ?,
	synopsis = ?,
	problem = ?,
	priority = ?,
	technician = ?,
	availability_time = ?
where
	id = ?
SQL
	my $availability_time = $data->{'availability_time'} ne '' ? $data->{'availability_time'} : undef;
	$self->pg->db->query($sql,
		$data->{'site'},
		$data->{'status'},
		$data->{'barcode'},
		$data->{'serial'},
		$data->{'author'},
		$data->{'location'},
		$data->{'contact'},
		$data->{'phone'},
		$data->{'email'},
		$data->{'section'},
		$data->{'synopsis'},
		$data->{'problem'},
		$data->{'priority'},
		$data->{'tech'},
		$availability_time
	);
	$self->_insert_troubleshooting($self->session('user_id'),$data->{'ticket_id'},$data->{'troubleshoot'}) if $data->{'troubleshoot'};
	$self->_add_history($data->{'ticket_id'},'update',$data->{'status'},$self->session('user_id'),undef,undef);
	return;
}

sub _insert_troubleshooting{
	my ($self,$tech,$ticket,$data) = @_;
	
my $troubleshooting_sql =<<SQL;
insert into troubleshooting(technician, ticket, troubleshooting) values(?,?,?)
SQL

	$self->pg->db->query($troubleshooting_sql,$tech,$ticket,$data);
	return;
}

sub _add_history{
	my ($self,$ticket,$update_type,$status,$updater,$notes,$time_worked) = @_;
	
my $sql =<<SQL;
insert into audit.ticket
	(update_type, status, notes, updater, ticket, time_worked) values (?,(select id from status where lower(status) = lower(?)),?,?,?,?)
SQL
	$self->pg->db->query($sql,$update_type,$status,$notes,$updater,$ticket,$time_worked);
	return;
}
1;