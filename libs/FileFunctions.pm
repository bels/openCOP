#!/usr/bin/perl

use 5.008009;
package FileFunctions;

use strict;
use warnings;
use File::Basename;
use DBI;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use FileFunctions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);

	$self->{'dbh'} = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'});

	return $self;
}

sub upload_attachment{
	my $self = shift;
	my %args = @_;
	my $errors;

	my $safe_filename_characters = "a-zA-Z0-9_.-";
	my $upload_dir = $args{'upload_dir'} . "/" . $args{'ticket'} . "/";
	my $filename = $args{'filename'};

	unless(-d $upload_dir){
	        mkdir($upload_dir,0775) or $errors->{'mkdir'} = "Could not create $upload_dir. Does www have write access to its parent directory?" && return $errors;
	}
	my ( $name, $path, $extension ) = fileparse ( $filename, '\..*' );
	$filename = $name . $extension;
	$filename =~ tr/ /_/;
	$filename =~ s/[^$safe_filename_characters]//g;
	
	if ( $filename =~ /^([$safe_filename_characters]+)$/ ){
		$filename = $1;
	} else {
		$errors->{'filename'} = "Filename contains invalid characters";
		return $errors;
	}
	my $upload_filehandle = $args{'attachment'};
	warn $upload_dir;

	open ( UPLOADFILE, ">$upload_dir" . "$filename" ) or $errors->{'upload'} = "$!" && return $errors;

	binmode UPLOADFILE;

	while ( <$upload_filehandle> ){
		print UPLOADFILE;
	}

	close UPLOADFILE;
	$errors->{'success'} = "1";
	return $errors;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

FileFunctions - TODO

=head1 SYNOPSIS

  use FileFunctions;

=head1 DESCRIPTION

TODO

=head2 VERSIONING

.1 Upload files from attachemnts.
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

markyys, <lt>jesusthefrog@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by bels

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
