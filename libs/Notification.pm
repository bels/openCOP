package Notification;

use 5.008009;
use strict;
use warnings;
use lib './';
use ReadConfig;
use Net::SMTP;
use MIME::Base64;

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
		
	$self->{'config'} = ReadConfig->new(config_type =>'YAML',config_file => "notification.yml");

	$self->{'config'}->read_config;
	
	$self->{'ticket_number'} = $args{'ticket_number'};
	
	return $self;
}

sub by_email{
	my $self = shift;
	my %args = @_;
	
	#return 1;
	my $smtp = Net::SMTP->new($self->{'config'}->{'mail_server'},Hello => $self->{'config'}->{'sending_server'}) or die "Couldn't connect to the smtp server";
	my $message_body = $self->{'config'}->{$args{'mode'}}; #basically when using this function you are going to have to call it as such: $notify->by_email(mode =>'ticket_create', to => $address) and the mode has to match one in notification.yml
	my $email = $args{'to'};
	my $company_name = $self->{'config'}->{'company_name'};
	
	$smtp->auth($self->{'config'}->{'email_user'},$self->{'config'}->{'email_password'});
		
	$smtp->mail($self->{'config'}->{'from'}) || handle_failure( $smtp, 'mail' );
	$smtp->to($email) || handle_failure( $smtp, 'to' );
	
	$smtp->data();
	$smtp->datasend("To: $email\n") || handle_failure( $smtp, 'data_send_to' );
	$smtp->datasend("From: $self->{'config'}->{'from'}\n") || handle_failure( $smtp, 'data_send_from' ) ;
	$smtp->datasend("Subject: Ticket # $self->{'ticket_number'}\n") || handle_failure( $smtp, 'data_send_subject' ) ;
	$smtp->datasend("\n");
    
	$smtp->datasend($message_body) || handle_failure( $smtp, 'data_send' );
	$smtp->datasend("\n\nThank you,\n\n$company_name") || handle_failure( $smtp, 'data_send' );
	$smtp->dataend() || handle_failure( $smtp, 'data_end' );
	$smtp->quit || handle_failure( $smtp, 'quit' );
}

sub handle_failure{
	my $smtp = shift;
	my $call = shift;

	my $smtp_msg = ( $smtp->message )[-1];
	chomp $smtp_msg;

	warn join( ':', $smtp->code, $call, $smtp_msg );
}

sub send_attachment{
	my $self = shift;
	my %args = @_;
	
	my $smtp = Net::SMTP->new($self->{'config'}->{'mail_server'},Hello => $self->{'config'}->{'sending_server'}) or die "Couldn't connect to the smtp server";
	my $message_body = $self->{'config'}->{$args{'mode'}}; #basically when using this function you are going to have to call it as such: $notify->by_email(mode =>'ticket_create', to => $address) and the mode has to match one in notification.yml
	my $email = $args{'to'};
	my $company_name = $self->{'config'}->{'company_name'};
	my $boundary = 'frontier';
	my $data_file = $args{'attachment_file'};

	open (DATA,$data_file) || die("Could not open the file");
		my @csv = <DATA>;
	close(DATA);

	$smtp->auth($self->{'config'}->{'email_user'},$self->{'config'}->{'email_password'});
		
	$smtp->mail($self->{'config'}->{'from'}) || handle_failure( $smtp, 'mail' );
	$smtp->to($email) || handle_failure( $smtp, 'to' );
	
	$smtp->data();
	$smtp->datasend("To: $email\n") || handle_failure( $smtp, 'data_send_to' );
	$smtp->datasend("From: $self->{'config'}->{'from'}\n") || handle_failure( $smtp, 'data_send_from' ) ;
	$smtp->datasend("Subject: $args{'attachment_name'}\n") || handle_failure( $smtp, 'data_send_subject' ) ;
	$smtp->datasend("\n");

	$smtp->datasend("MIME-Version: 1.0\n");
	$smtp->datasend("Content-type: multipart/mixed;\n\tboundary=$boundary\n");
	$smtp->datasend("\n");
	$smtp->datasend("--$boundary\n");
	$smtp->datasend("Content-type: text/plain\n");
	$smtp->datasend("Content-Disposition: quoted-printable\n");
	$smtp->datasend($message_body) || handle_failure( $smtp, 'data_send' );
	$smtp->datasend("\n\nThank you,\n\n$company_name") || handle_failure( $smtp, 'data_send' );
	$smtp->datasend("--$boundary\n");
	$smtp->datasend("Content-Type: $args{'content_type'}; name=$data_file\n");
	$smtp->datasend("Content-Disposition: attachment; filename=$data_file\n");
	$smtp->datasend("\n");
	$smtp->datasend("@csv\n");
	$smtp->datasend("--$boundary--\n");
    
	$smtp->dataend() || handle_failure( $smtp, 'data_end' );
	$smtp->quit || handle_failure( $smtp, 'quit' );
}

sub new_user{
	my $self = shift;
	my %args = @_;
	
	my $smtp = Net::SMTP->new($self->{'config'}->{'mail_server'},Hello => $self->{'config'}->{'sending_server'}) or die "Couldn't connect to the smtp server";
	my $message_body = $self->{'config'}->{$args{'mode'}}; #basically when using this function you are going to have to call it as such: $notify->by_email(mode =>'ticket_create', to => $address) and the mode has to match one in notification.yml
	my $email = $args{'to'};
	my $company_name = $self->{'config'}->{'company_name'};
	
	$smtp->auth($self->{'config'}->{'email_user'},$self->{'config'}->{'email_password'});
		
	$smtp->mail($self->{'config'}->{'from'}) || handle_failure( $smtp, 'mail' );
	$smtp->to($email) || handle_failure( $smtp, 'to' );
	
	$smtp->data();
	$smtp->datasend("To: $email\n") || handle_failure( $smtp, 'data_send_to' );
	$smtp->datasend("From: $self->{'config'}->{'from'}\n") || handle_failure( $smtp, 'data_send_from' ) ;
	$smtp->datasend("Subject: Welcome to $company_name Helpdesk\n") || handle_failure( $smtp, 'data_send_subject' ) ;
	$smtp->datasend("\n");
    
	$smtp->datasend("Hello " . $args{'first'} . " " . $args{'mi'} . " " . $args{'last'} . ",\n") || handle_failure( $smtp, 'data_send' );
	$smtp->datasend($message_body) || handle_failure( $smtp, 'data_send' );
	$smtp->datasend("\n\nUsername: " . $args{'alias'} . "\nPassword: " . $args{'password'}) || handle_failure( $smtp, 'data_send' );
	$smtp->datasend("\n\nThank you,\n\n$company_name") || handle_failure( $smtp, 'data_send' );
	$smtp->dataend() || handle_failure( $smtp, 'data_end' );
	$smtp->quit || handle_failure( $smtp, 'quit' );
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
