package Opencop::Model::Reports;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub list_all{
	my $self = shift;

	return $self->pg->db->query('select name,report from reports where active = true order by name desc')->arrays->to_array;
}

sub retrieve{
	my ($self,$data) = @_;
	
	my $report = $data->{'report'};

my $timeframe_sql =<<"SQL";
select * from $report(?::INTERVAL)
SQL

my $start_end_sql =<<"SQL";
select * from $report(?::DATE,?::DATE)
SQL

my $timeframe_company_sql =<<"SQL";
select * from $report(?::INTERVAL,?::UUID)
SQL

my $start_end_company_sql =<<"SQL";
select * from $report(?::DATE,?::DATE,?::UUID)
SQL

my $ticket =<<"SQL";
select * from $report(?::UUID)
SQL
	
	if(defined($data->{'timeframe'}) && $data->{'timeframe'} ne ""){
		return $self->pg->db->query($timeframe_sql,$data->{'timeframe'})->hashes->to_array; 
	}
	if(defined($data->{'start'}) && $data->{'start'} ne ""){
		return $self->pg->db->query($start_end_sql,$data->{'start'},$data->{'end'})->hashes->to_array; 
	}
	if((defined($data->{'timeframe'}) && $data->{'timeframe'} ne "") && (defined($data->{'company'}) && $data->{'company'} ne "")){
		return $self->pg->db->query($timeframe_company_sql,$data->{'timeframe'},$data->{'company'})->hashes->to_array; 
	}
	if((defined($data->{'start'}) && $data->{'start'} ne "") && (defined($data->{'company'}) && $data->{'company'} ne "")){
		return $self->pg->db->query($start_end_company_sql,$data->{'start'},$data->{'end'},$data->{'company'})->hashes->to_array; 
	}
	if(defined($data->{'ticket'}) && $data->{'ticket'} ne ""){
		my $ticket_id = $self->pg->db->query('select id from ticket where ticket = ?',$data->{'ticket'})->hash->{'id'};
		return $self->pg->db->query($ticket,$ticket_id)->hash;
	}
}

1;