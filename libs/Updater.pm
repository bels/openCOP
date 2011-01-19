#!/usr/bin/perl

use 5.008009;
package Updater;

use strict;
use warnings;
use lib './libs';
use ReadConfig;
use POSIX 'strftime';
use YAML;
use Data::Dumper;
use DBI;

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
	chomp($self->{'opencop_dir'});
	$self->{'working_dir'} = "/tmp/opencop_update";
	$self->{'dbh'} = DBI->connect("dbi:$args{'db_type'}:dbname=$args{'db_name'}",$args{'user'},$args{'password'},{ pg_enable_utf8 => 1 });
	if(! -d $self->{'working_dir'}){
		qx(mkdir $self->{'working_dir'});
	}

	return $self;
}

sub check_version{
	my $self = shift;
	my %args = @_;

	if(defined($config->{'update_url'})){
		qx(curl -s $config->{'update_url'}/latest_version -o $self->{'working_dir'}/opencop_latest);
		open (VERSION, "$self->{'working_dir'}/opencop_latest") or return(my $result = {error => 3, message => "Could not open $self->{'working_dir'}/opencop_latest",});
		my @line = <VERSION>;
		my $version = $line[0];
		close VERSION or return($result = {error => 4, message => "Could not close $self->{'working_dir'}/opencop_latest",});
		chomp($version);
		my $oversion = $version;
		$oversion =~ s/\.//g;
		$config->{'version'} =~ s/\.//g;
		warn $config->{'version'};
		warn $oversion;
		if($oversion <= $config->{'version'}){
			return my $result = {error => 0, message => "Already at latest version", version => $version, calcv => $oversion, calcc => $config->{'version'}};
		} else {
			return my $result = {error => 1, message => "Newer version found", version => $version, calcv => $oversion, calcc => $config->{'version'}};
		}
	} else {
		die "No update URL specified";
		return my $result = {error => 2, message => "No update URL specified"};
	}
}


sub get_package{
	my $self = shift;
	my %args = @_;

	my $md5_url = "$config->{'update_url'}/opencop_$args{'version'}.md5";
	my $md5_path = "$self->{'working_dir'}/opencop_$args{'version'}.md5";
	my $package_url = "$config->{'update_url'}/opencop_$args{'version'}.tar.bz2";
	my $package_path = "$self->{'working_dir'}/opencop_$args{'version'}.tar.bz2";
	warn $args{'version'};

	qx(curl -s $md5_url -o $md5_path);

	qx(curl -s $package_url -o $package_path);
	my $tar = "opencop_$args{'version'}.tar.bz2";
	my $error = check_md5($md5_path,$self->{'working_dir'},$tar);
	my $i = 0;
	while($error && $i<5){
		qx(rm $package_path);
		qx(curl -s $package_url -o $package_path);
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
	qx(sed -i "" 's=$tar=$wd/$tar=' $md5);
	qx(gmd5sum -c $md5);
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

sub backup_db{
	my $self = shift;
	my %args = @_;
	my $date = strftime('%Y-%m-%d-%H-%M-%S', localtime);

	qx(pg_dump -U $args{'db_user'} $args{'db_name'} > /tmp/$args{'db_name'}_$date.sql);
	return $?;
}

sub destroy{
	my $self = shift;
	my %args = @_;

	qx(rm -rf $self->{'working_dir'});
	my $rmfiles = $self->{'opencop_dir'} . "/*.yml";
	qx(rm $rmfiles);
	return $?;
}

sub merge_changes{
	my $self = shift;
	my %args = @_;
	
	qx(tar -xjf $args{'package_path'} -C $self->{'opencop_dir'});
	return $?;
}

sub update_db{
	my $self = shift;
	my %args = @_;

	my $query;
	my $sth;
	my @configs;

	my $dir = $self->{'opencop_dir'} . "/install/";
	opendir(DIR, $dir) or die "Couldn't open $self->{'opencop_dir'}: $!";
	LINE: while(my $FILE = readdir(DIR)){
		next LINE if($FILE =~ /^\.\.?/);
		if($FILE =~ m/\.sql$/){
			my @sqlver = split(/\./,$FILE);
			warn $sqlver[0];
			warn  $args{'version'};
			if($sqlver[0] > $args{'version'}){
				push(@configs,$FILE);
			}
		}
	}
	closedir(DIR);

	@configs = sort({$a cmp $b} @configs);
	my $error = 0;
	foreach(@configs){
		qx(psql -U $config->{'db_user'} $config->{'db_name'} < $dir$_);
		if($?){
			$error++;
		}
#		my @scratch = split('.',$_);
#		if($scratch[0] <= $args{'version'}){
#			my $query = "";
#			my $new_statement = 0;
#			open FILE, "$_" or die "Couldn't open $_: $!";
#			foreach(<FILE>){
#				if($_ =~ m/^--##$/){
#					$new_statement = 1;
#				}
#				if($new_statement == 1){
#					$_ =~ s/--##//;
#					$query .= $_;
#				}
#				if($_ =~ m/^--\$\$$/){
#					$sth = $self->{'dbh'}->prepare($query) or warn "Could not prepare query while updating database.";
#					$sth->execute;
#					$new_statement = 0;
#					$query = "";
#				}
#			}
#		}
	}
	return $error;
}

sub update_config{
	my $self = shift;
	my %args = @_;

	my @configs;
	my $dir = $self->{'opencop_dir'};
	opendir(DIR, $dir) or die "Couldn't open $self->{'opencop_dir'}: $!";
	LINE: while(my $FILE = readdir(DIR)){
		next LINE if($FILE =~ /^\.\.?/);
		if($FILE =~ m/\.yml$/){
			push(@configs,$FILE);
		}
	}
	closedir(DIR);

	foreach(@configs){
		my $oldconfig = "/usr/local/etc/opencop/" . $_;
		my $newconfig = $self->{'opencop_dir'} . "/" . $_;
		my $old = YAML::LoadFile($oldconfig);
		my $new = YAML::LoadFile($newconfig);
		foreach(keys %$new){
			unless(defined($old->{$_})){
				$old->{$_} = $new->{$_};
			}
		}
		YAML::DumpFile($oldconfig,$old);
	}
	my $tempconfig = "/usr/local/etc/opencop/config.yml";
	my $temp = YAML::LoadFile($tempconfig);
	$temp->{'version'} = $args{'version'};
	YAML::DumpFile($tempconfig,$temp);
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
