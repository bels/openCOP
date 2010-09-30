package CustomerFunctions;

use 5.008009;
use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);

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

our $VERSION = '0.54';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);

	$self->{'dbh'} = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'});
	
	return $self;
}

sub duplicate_check{
	my $self = shift;
	my %args = @_;
	
	my $query = "select count(*) from customers where alias = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query) or die $!;
	$sth->execute or die $!;
	my $result = $sth->fetchrow_hashref or die $!;
	
	return $result->{'count'};
}

sub create_user{
	my $self = shift;
	my %args = @_;
	my ($day,$month,$year) = (localtime)[3,4,5];
	#my $today = ($year + 1900) . "-" . ($month + 1) . "-" . $day; #replaced with using default values of current_time in postgresql
	my $password = md5_hex($args{'password'});

	my $query = "insert into customers (alias,password,email, active,first, middle_initial, last, site) values ('$args{'alias'}','$password','$args{'email'}',TRUE,'$args{'first'}','$args{'mi'}','$args{'last'}','$args{'site'}')";
	my $sth = $self->{'dbh'}->prepare($query) or return undef;
	$sth->execute or return undef;

}

sub delete_user{
	my $self = shift;
	my %args = @_;
	
	my $query = "delete from customers where alias = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
}

sub reset_password{
	my $self = shift;
	my %args = @_;
	
	my $password = md5_hex($args{'password'});
	
	my $query = "update customers set password = '$password' where name = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
}

sub get_user_info{
	my $self = shift;
	my %args = @_;

	my $query = "select * from customers where alias = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;

	my $results = $sth->fetchrow_hashref;
#need to get the number of views, friends, followers? and add it to the results hashref that is passing back.  Need to implement these things first though
	return $results;
}

sub update_profile{
	my $self = shift;
	my %args = @_;
	
	my $query ;
	if($args{'column'} eq 'email')
	{
		$query = "update customers set email = ? where alias = ?";
	}
	if($args{'column'} eq 'zip')
	{
		$query = "update customers set zip = ? where alias = ?";
	}
	if($args{'column'} eq 'password')
	{
		$args{'value'} = md5_hex($args{'value'});
		$query = "update customers set password = ? where alias = ?";
	}
	if($args{'column'} eq 'avail_contact')
	{
		$query = "update customers set avail_contact = ? where alias = ?";
	}
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'value'},$args{'alias'});
}

sub upload_picture{
	my $self = shift;
	my %args = @_;
	
	my $query = "update customers set picture = '$args{'picture'}' where alias = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
}

sub get_user_id{
	my $self = shift;
	my %args = @_;
	
	my $query = "select id from customers where alias = '$args{'alias'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
	my $result = $sth->fetchrow_hashref;
	
	return $result->{'id'};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Could be quickly adapted to other database driven website

=head1 SYNOPSIS

  use CustomerFunctions;
  

=head1 DESCRIPTION

This is a set of wrapper functions that make deploying a database driven website quicker and more fault
tolerant.  These functions are setup to use postgresql but could easily be changed to use mysql

Split from UserFunctions.  These functions may be more related to how a customer would interact with you extending beyond creating accounts.  This may end up merging back into UserFunctions but for now it's separate.

=head2 VERSIONING

.54 - Renamed to CustomerFunctions split off of UserFunctions.  
.53 - fixed bug in dup check (was missing apostrophe)
.52 - changed database fields to match germ_playground

.51 - fixed bug in upload_picture where the picture would get set for everyone
	
.5 - Functions added
	get _user_id
	upload_picture
	
.41 - made update_profile actually work

.4 - Functions added
	update_profile

.3 - Functions
	get_user_info

.2 - Functions
	authenticate_user
	reset_password

.1 - Functions
	new
	duplicate_check
	create_user
	delete_user

=head2 EXPORT

All by default



=head1 SEE ALSO

=head1 AUTHOR

Bels, E<lt>bels@belfield.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.


=cut
