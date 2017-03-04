package Opencop::Model::Audit;
use Mojo::Base -base;

has 'pg';
has 'debug';

sub page_visit{
	my ($self,$data) = @_;
	
	my $important_data = {
		method => $data->req->method,
		uri => $data->req->url->path,
		protocol => $data->req->url->base->scheme,
		host => $data->req->headers->host,
		port => $data->local_port,
		referring_page => $data->req->headers->referrer,
		client => {
			address => $data->remote_address,
			user_agent => $data->req->headers->user_agent,
			port => $data->remote_port
		}
	};
	#make this a configuration file option
	$self->{'db'}->db->query(
		'insert into audit.traffic(method,uri,protocol,host,host_port,referring_page,client_ip,user_agent,client_port) values (?,?,?,?,?,?,?,?,?)',
		$important_data->{'method'},
		$important_data->{'uri'},
		$important_data->{'protocol'},
		$important_data->{'host'},
		$important_data->{'port'},
		$important_data->{'referring_page'},
		$important_data->{'client'}->{'address'},
		$important_data->{'client'}->{'user_agent'},
		$important_data->{'client'}->{'port'}
	);

	return;
}

1;