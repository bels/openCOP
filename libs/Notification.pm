package Notification;

use 5.008009;
use strict;
use warnings;
use lib './';
use ReadConfig;
use Net::SMTP::TLS;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use UserFunctions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.1';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);
		
	$self->{'config'} = ReadConfig->new(config_type =>'YAML',config_file => "../notification.yml");

	$self->{'config'}->read_config;
	
	$self->{'ticket_number'} = $args{'ticket_number'};
	
	return $self;
}

sub by_email{
	my $self = shift;
	my %args = @_;
	
	my $smtp = new Net::SMTP::TLS($self->{'config'}->{'mail_server'},User => $self->{'config'}->{'email_user'},Password => $self->{'config'}->{'email_password'}) or die "Couldn't connect to the smtp server";
	my $message_body = $self->{'config'}->{$args{'mode'}}; #basically when using this function you are going to have to call it as such: $notify->by_email(mode =>'ticket_create', to => $address) and the mode has to match one in notification.yml
	my $email = $args{'to'};
	$smtp->mail($self->{'config'}->{'from'}) || handle_failure( $smtp, 'mail' );
	$smtp->to($email) || handle_failure( $smtp, 'to' );
	$smtp->data();
    
	$smtp->datasend("To: $email") || handle_failure( $smtp, 'data_send_to' );
	$smtp->datasend("From: $self->{'config'}->{'from'}") || handle_failure( $smtp, 'data_send_from' ) ;
	$smtp->datasend("Subject: Ticket #$self->{'ticket_number'}") || handle_failure( $smtp, 'data_send_subject' ) ;
	$smtp->datasend("\n");
    
	$smtp->datasend($message_body) || handle_failure( $smtp, 'data_send' );
	$smtp->dataend() || handle_failure( $smtp, 'data_end' );
	$smtp->quit || handle_failure( $smtp, 'quit' );
}

sub handle_failure{
	my $smtp = shift;
	my $call = shift;

	my $smtp_msg = ( $smtp->message )[-1];
	chomp $smtp_msg;

	die join( ':', $smtp->code, $call, $smtp_msg );
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Notification

=head1 SYNOPSIS

  use Notification;
  

=head1 DESCRIPTION

A library to make notifying users/customers easy and pain free

=head2 VERSIONING

.1 - Functions
	new
	by_email

=head2 EXPORT

All by default



=head1 SEE ALSO

=head1 AUTHOR

Bels, E<lt>bels@belfield.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut