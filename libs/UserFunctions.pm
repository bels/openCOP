package UserFunctions;

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

our $VERSION = '0.53';


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
	
	my $query = "select count(*) from users where alias = ?";
	my $sth = $self->{'dbh'}->prepare($query) or die $!;
	$sth->execute($args{'alias'}) or die $!;
	my $result = $sth->fetchrow_hashref or die $!;
	
	return $result->{'count'};
}

sub create_user{
	my $self = shift;
	my %args = @_;
	my ($day,$month,$year) = (localtime)[3,4,5];
	#my $today = ($year + 1900) . "-" . ($month + 1) . "-" . $day; #replaced with using default values of current_time in postgresql
	my $password = md5_hex($args{'password'});

	my $query = "
		insert into users (
			first,
			last,
			middle_initial,
			alias,
			password,
			email,
			site,
			active
		) values (
			?,
			?,
			?,
			?,
			?,
			?,
			?,
			TRUE
		)
	";
	my $sth = $self->{'dbh'}->prepare($query) or return undef;
	$sth->execute(
			$args{'first'},
			$args{'last'},
			$args{'mi'},
			$args{'alias'},
			$password,
			$args{'email'},
			$args{'site'}
	) or return undef;
	$query = "
		select
			last_value
		from
			users_id_seq
		;
	";
	$sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
	my $uid = $sth->fetchrow_hashref;
	$query = "
		insert into alias_aclgroup (
			alias_id,
			aclgroup_id
		) values (
			?,
			?
		);
	";
	$sth = $self->{'dbh'}->prepare($query);
	$sth->execute($uid->{'last_value'},$args{'group'}) or return undef;

}

sub delete_user{
	my $self = shift;
	my %args = @_;
	
	my $query = "delete from users where alias = ?";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'alias'});
}

sub reset_password{
	my $self = shift;
	my %args = @_;
	
	my $password = md5_hex($args{'password'});
	
	my $query = "update users set password = ? where name = ?";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($password,$args{'alias'});
}

sub get_user_info{
	my $self = shift;
	my %args = @_;

	my $query = "select * from users where id = ?";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'user_id'});

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
		$query = "update users set email = ? where alias = ?";
	}
	if($args{'column'} eq 'password')
	{
		$args{'value'} = md5_hex($args{'value'});
		$query = "update users set password = ? where alias = ?";
	}
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'value'},$args{'alias'});
}

sub get_user_name{
	my $self = shift;
	my %args = @_;
	
	my $query = "select alias from users where id = ?";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'user_id'});
	my $result = $sth->fetchrow_hashref;
	return $result->{'id'};
}

sub get_groups{
	my $self = shift;
	my %args = @_;
	my $query = "select distinct(alias_aclgroup.aclgroup_id),name from alias_aclgroup join aclgroup on alias_aclgroup.aclgroup_id = aclgroup.id where (alias_id = ?);";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'id'});
	my $group = $sth->fetchall_hashref('aclgroup_id');
	return $group;
}

sub is_admin{
	my $self = shift;
	my %args = @_;

	my $query = "select is_admin(?)";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'id'});
	my $result = $sth->fetchrow_hashref;
	my $is_admin = $result->{'is_admin'};
	return $is_admin;
}

sub get_permissions{
	my $self = shift;
	my %args = @_;

	sub isequal($$){
		if(defined($_[0]) && $_[0] == 0){
			return $_[0];
		} else {
			return $_[1];
		}
	}
	my $permissions = {};

	my $query = "select distinct(aclgroup_id) from alias_aclgroup where (alias_id = ?);";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute($args{'id'});
	my $group = $sth->fetchall_hashref('aclgroup_id');
	foreach (keys %$group){
		$query = "select * from section_aclgroup where aclgroup_id = ?;";
		$sth = $self->{'dbh'}->prepare($query);
		$sth->execute($_);
		my $results = $sth->fetchall_hashref('id');
		foreach (keys %$results){
			$permissions->{$results->{$_}->{'section_id'}} = {
				'read'		=>	isequal($permissions->{$results->{$_}->{'section_id'}}->{'read'},$results->{$_}->{'aclread'}),
				'create'	=>	isequal($permissions->{$results->{$_}->{'section_id'}}->{'create'},$results->{$_}->{'aclcreate'}),
				'update'	=>	isequal($permissions->{$results->{$_}->{'section_id'}}->{'update'},$results->{$_}->{'aclupdate'}),
				'delete'	=>	isequal($permissions->{$results->{$_}->{'section_id'}}->{'delete'},$results->{$_}->{'acldelete'}),
			};
		}
	}

	return $permissions;
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

UserFunctions - Perl extension for Veem
Could be quickly adapted to other database driven website

=head1 SYNOPSIS

  use UserFunctions;
  

=head1 DESCRIPTION

This is a set of wrapper functions that make deploying a database driven website quicker and more fault
tolerant.  These functions are setup to use postgresql but could easily be changed to use mysql

=head2 VERSIONING

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
