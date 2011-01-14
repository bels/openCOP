#!/usr/bin/env perl

#if($ARGV[0] eq "enable")
#{
#	enable();
#}
#if($ARGV[0] eq "disable")
#{
#	disable();
#}
#MODULE_NAME=Backup

use warnings;

use lib './libs';
use ReadConfig;
use JSON;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'password'},{ pg_enable_utf8 => 1 });
if(! -d $config->{'backup_dir'}){
	qx(mkdir $config->{'backup_dir'});
}
use CGI;
my $q = CGI->new;
my $vars = $q->Vars;

#if($ARGV[0] eq "change_type"){
#	change_type();
#}
my $json;
my $object;

if($vars->{'object'}){
	$json = $vars->{'object'};
	$object = from_json($json);
}

if($ARGV[0]){
	&{$ARGV[0]}();
} elsif($object->{'action'}){
	&{$object->{'action'}}($object);
}

if($config->{'backup_mask'}){
	if($config->{'backup_mask'} % 2 != 0){
		backup_db($config);
	}
	if($config->{'backup_mask'} - 1 > 0){
		backup_config($config);
	}
} else {
	exit;
}

sub change_type{
	my $object = shift;
	my $config;
	my $return;
	print "Content-type: application/json\n\n";
	if (-e "/usr/local/etc/opencop/config.yml")
	{
		$config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");
	}
	else
	{
		$return = {
			error	=>	1,
			message	=>	"Config file (/usr/local/etc/opencop/config.yml) does not exist or the permissions on it are not correct.",
		};
		my $newjson = to_json($return);
		print $newjson;
		exit;
	}
	
	$config->{'backup_mask'} = $object->{'mask'};
	YAML::DumpFile('/usr/local/etc/opencop/config.yml', $config);
	$return = {
		error	=>	0,
		message	=>	"Success",
		mask	=>	$config->{'backup_mask'},
	};
	my $newjson = to_json($return);
	print $newjson;
	exit;
}

sub modify_schedule{
	my $object = shift;
	my $return;
	my @temp = split('\/',$0);
	my $thisfile = pop(@temp);
	chomp($thisfile);

	my $os = qx(uname);
	chomp($os);

	my $path = qx(pwd);
	chomp($path);
	my $complete_path = $path . "/modules/backup.pl\n";

	my $newcron = "$object->{'min'} $object->{'hour'} $object->{'dom'} object->{'month'} $object->{'dow'} /usr/bin/env perl $complete_path\n";

	my $crontab = qx(crontab -l);
	chomp($crontab);
	my @crontab = split('\n',$crontab);
	open NEW, ">>/tmp/opencop/newcron";
	foreach my $line (@crontab){
		chomp($line);
		if($line =~ m/backup.pl$/){
			# nothing
		} else {
			print NEW "$line\n";
		}
	}
	print NEW $newcron;
	close NEW;
	$return = {
		error	=>	0,
		message	=>	"Success",
	};
	my $newjson = to_json($return);
	print $newjson;
	exit;
}

sub backup_config{
	my $config = shift;
	my $date = strftime('%Y-%m-%d-%H-%M-%S', localtime);
	my $dirs = "styles/ images/ javascripts/ *.yml /usr/local/etc/opencop/";
	qx(tar cPjf "$config->{'backujp_dir'}/opencop_config_backup_$date.tar.bz2" $dirs);\
	return $?;
}

sub backup_db{
	my $args = shift;
	my $date = strftime('%Y-%m-%d-%H-%M-%S', localtime);
	qx(pg_dump -U $args->{'db_user'} $args->{'db_name'} > $config->{'backup_dir'}/$args->{'db_name'}_$date.sql);
	return $?;
}

sub enable{
	my @temp = split('\/',$0);
	my $thisfile = pop(@temp);
	chomp($thisfile);

	my $os = qx(uname);
	chomp($os);

	my $file = "/tmp/opencop/opencop_crontab";
	my $path = qx(pwd);
	chomp($path);
	my $complete_path = $path . "/modules/backup.pl\n";

	open NEWCRON, ">>/tmp/opencop/" . $thisfile . "_schedule";
	print NEWCRON "0 23 * * 6 /usr/bin/env perl $complete_path";
	close NEWCRON;

	open FILE, ">>$file";
	print FILE "add:/tmp/opencop/" . $thisfile  . "_schedule\n";
	close(FILE);

	my $rmfile = "/tmp/opencop/" . $thisfile . "_schedule";
	qx(chmod 777 $file);
	qx(chmod 777 $rmfile);

	my $config;
	if (-e "/usr/local/etc/opencop/config.yml")
	{
		$config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");
	}
	else
	{
		die "Config file (/usr/local/etc/opencop/config.yml) does not exist or the permissions on it are not correct.\n";
	}
	
	$config->{'backup_mask'} = '3';
	YAML::DumpFile('/usr/local/etc/opencop/config.yml', $config);

	exit;
}

sub disable{
	my @temp = split('\/',$0);
	my $thisfile = pop(@temp);
	chomp($thisfile);

	my $file = "/tmp/opencop/opencop_crontab";
	open FILE, ">>$file";
	print FILE "remove:" . $thisfile . "\n";
	close(FILE);

	qx(chmod 777 $file);

	my $config;
	if (-e "/usr/local/etc/opencop/config.yml")
	{
		$config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");
	}
	else
	{
		die "Config file (/usr/local/etc/opencop/config.yml) does not exist or the permissions on it are not correct.\n";
	}
	
	$config->{'backup_mask'} = '0';
	YAML::DumpFile('/usr/local/etc/opencop/config.yml', $config);

	exit;
}
