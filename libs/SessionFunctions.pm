package SessionFunctions;

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

# This allows declaration	use SessionFunctions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);
	$self->{'dbh'} = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'}) or die "SessionFunctions::new: Database connection error: ".$DBI::errstr;
	
	return $self;
}

sub authenticate_user{
	my $self = shift;
	my %args = @_;
	
	my $password = md5_hex($args{'password'});
	
	my $query = "select count(*) from $args{'users_table'} where alias = '$args{'alias'}' and password = '$password'";
	my $sth = $self->{'dbh'}->prepare($query) or die "Preparing the query for authenticate_user in SessionFunctions";
	$sth->execute or die "Executing the query for authenticate_user in SessionFunctions";
	my $result = $sth->fetchrow_hashref or die "Fetching the results for authenticate_user in SessionFunctions";
	
	return $result->{'count'};
}

sub create_session_id{
	my $self = shift;
	my %args = @_;

	#generate a random number

	srand(time ^ $$ ^ unpack "%L*", `ps axww | gzip`);
	my $random_number = int(rand(10000));

	my $query = "select count(*) from $args{'auth_table'} where id = $random_number";
	my $sth = $self->{'dbh'}->prepare($query)  or die "Preparing the query for create_session_id in SessionFunctions";
	$sth->execute  or die "Executing the query for create_session_id in SessionFunctions";
	my $result = $sth->fetchrow_hashref  or die "Fetching the results for create_session_id in SessionFunctions";

	if($result->{'count'} == 0)
	{
		my($sec,$min,$hour,$day,$month,$year) = (localtime)[0,1,2,3,4,5];
		my $today = ($year + 1900) . "-" . ($month + 1) . "-" . $day . " $hour:$min:$sec";
		$query = "insert into $args{'auth_table'} (id,user_id,session_key,created) values($random_number,'$args{'user_id'}','$args{'session_key'}','$today')";
		$sth= $self->{'dbh'}->prepare($query)  or die "Preparing the second query for create_session_id in SessionFunctions";
		$sth->execute  or die "Executing the second query for create_session_id in SessionFunctions";
		return $random_number;
	}
	else
	{
		create_session_id();
	}
}

sub is_logged_in{
	my $self = shift;
	my %args = @_;

	my $query = "select count(*) from $args{'auth_table'} where id = $args{'id'} and session_key = '$args{'session_key'}'";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
	my $result = $sth->fetchrow_hashref;
	
	if($result->{'count'} > 1 || $result->{'count'} < 0)
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

sub get_name_for_session{
	my $self = shift;
	my %args = @_;
	
	my $query = "select user_id from $args{'auth_table'} where id = $args{'id'}";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
	my $result = $sth->fetchrow_hashref;
	
	return $result->{'user_id'};
}

sub logout{
	my $self = shift;
	my %args =@_;
	
	my $query = "delete from $args{'auth_table'} where id = $args{'id'}";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
}

sub add_visitor
{
	my $self = shift;
	my $ip = shift;
	my $query = "insert into visitors (ip) values('$ip')";
	my $sth = $self->{'dbh'}->prepare($query);
	$sth->execute;
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

SessionFunctions - Perl extension for handling session information in veem

=head1 SYNOPSIS

  use SessionFunctions;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for SessionFunctions, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 VERSIONING

.02 - Modified the code to be more generic so it will be easier to implement this module in other projects
.011 - Modified for use in germ
.01 - Initial write. Function list
	new
	authenticate_user
	get_name_for_session
	is_logged_in
	logout
=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

bels, E<lt>bels@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
