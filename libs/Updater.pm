#!/usr/bin/perl

use 5.008009;
package Updater;

use strict;
use warnings;
use lib './libs';
use ReadConfig;
use POSIX 'strftime';

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ReportFunctions ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

# Preloaded methods go here.

sub new{
	my $package = shift;
	my %args = @_;
	
	my $self = bless({},$package);

	$self->{'opencop_dir'} = qx(pwd);
	$self->{'working_dir'} = "/tmp/opencop_update";
	if(! -d $self->{'working_dir'}){
		qx(mkdir $self->{'working_dir'});
	}

	return $self;
}

sub check_version{
	my $self = shift;
	my %args = @_;

	qx(curl $config->{'update_url'}/latest_version -o $self->{'working_dir'}/opencop_latest);
	open (VERSION, "$self->{'working_dir'}/opencop_latest") or die "Could not open $self->{'working_dir'}/opencop_latest";
	my @line = <VERSION>;
	my $version = $line[0];
	close VERSION or die "Could not close $self->{'working_dir'}/opencop_latest";
	chomp($version);
	if($version <= $config->{'version'}){
		return my $result = {error => 0, message => "Already at latest version", version => $version};
	} else {
		return my $result = {error => 1, message => "Newer version found", version => $version};
	}

}


sub get_package{
	my $self = shift;
	my %args = @_;

	my $md5_url = "$config->{'update_url'}/opencop_$args{'version'}.md5";
	my $md5_path = "$self->{'working_dir'}/opencop_$args{'version'}.md5";
	my $package_url = "$config->{'update_url'}/opencop_$args{'version'}.tar.bz2";
	my $package_path = "$self->{'working_dir'}/opencop_$args{'version'}.tar.bz2";

	qx(curl $md5_url -o $md5_path);

	qx(curl $package_url -o $package_path);
	my $tar = "opencop_$args{'version'}.tar.bz2";
	my $error = check_md5($md5_path,$self->{'working_dir'},$tar);
	my $i = 0;
	while($error && $i<5){
		qx(rm $package_path);
		qx(curl $package_url -o $package_path);
		$error = check_md5($md5_path,$self->{'working_dir'},$tar);
		$i++;
		unless($error){
			$i = 0;
		}
	}
	if($i){
		return my $result = {error => 1, message => "Failed to verify checksum of $package_url"};
	}
	return my $result = {error => 0, message => "Update downloaded to $package_path", package_path => $package_path};
}


sub check_md5{
	my ($md5,$wd,$tar) = @_;
	qx(sed -i 's=$tar=$wd/$tar=' $md5);
	qx(md5sum -c $md5);
	return $?;
}

sub backup_config{
	my $self = shift;
	my %args = @_;
	my $date = strftime('%Y-%m-%d-%H-%M-%S', localtime);
	my $dirs = "styles/ images/ javascripts/ *.yml /usr/local/etc/opencop/";
	qx(tar cPjf "/tmp/opencop_config_backup_$date.tar.bz2" $dirs);
	return $?;
}

sub destroy{
	my $self = shift;
	my %args = @_;

	qx(rm -rf $self->{'working_dir'});
	return $?;
}

sub merge_changes{
	my $self = shift;
	my %args = @_;
	
	qx(tar --mode 770 -xjf $args{'package_path'} -C $self->{'opencop_dir'});
	return $?;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

ReportFunctions - TODO

=head1 SYNOPSIS

  use Updater;

=head1 DESCRIPTION

TODO

=head2 VERSIONING

.1 updates opencop to the latest version available
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
