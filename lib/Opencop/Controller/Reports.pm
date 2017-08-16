package Opencop::Controller::Reports;
use Mojo::Base 'Mojolicious::Controller';

sub view_all{
	my $self = shift;

	$self->stash(
		reports => $self->reports->list_all
	);
}

sub view{
	my $self = shift;

	$self->stash(
		js => ['/js/common/mustache.js','/js/common/jquery.mustache.js','/js/common/bootstrap-datepicker.min.js','/js/private/report.js'],
		current_report => $self->param('report')
	);
}

sub retrieve_report{
	my $self = shift;
	
	my $data = {
		report => $self->param('report'),
		timeframe => $self->param('timeframe'),
		start => $self->param('start-date'),
		end => $self->param('end-date'),
		ticket => $self->param('ticket'),
		company => $self->param('company')
	};

	my $report = $self->reports->retrieve($data);
	$self->render(json => {success => Mojo::JSON->true, report => $report}, status => 200);
}
1;