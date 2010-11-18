#!/usr/bin/perl


use 5.008009;
package ReadConfig;

use strict;
use warnings;

use YAML ();

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ReadConfig ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.011';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);

	$self->{'config_type'} = $args{'config_type'};
	$self->{'config_file'} = $args{'config_file'};

	return $self;
}

sub read_config{
	my $self = shift;

	my $type = uc($self->{'config_type'});
	my %config_types = (
		'YAML' => read_yaml($self)
	);
}

sub read_yaml{
	my $self = shift;

	if (-e $self->{'config_file'})
	{
		my $config = YAML::LoadFile($self->{'config_file'});
		my %config_data = %{$config};
		foreach my $key (%config_data)
		{
			$self->{$key} = $config_data{$key};
		}
	}
	else
	{
		die "Tried to read in a YAML config file and the location given is not correct";
	}
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

ReadConfig - generic configuration reader

=head1 SYNOPSIS

  use ReadConfig;

=head1 DESCRIPTION

ReadConfig reads different config files that map to hashes well.  For example
it reads YAML config files and takes the ATTRIB: VALUE pair and turns them into
parameters for the object created when calling ReadConfig->new() inside of your
PERL script

=head2 VERSIONING

.1 reads yaml config files
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

bels, <lt>bels@lfmcorp.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
