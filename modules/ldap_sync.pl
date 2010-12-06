#!/usr/bin/env perl
if($ARGV[0] eq "enable")
{
	enable();
}
if($ARGV[0] eq "disable")
{
	disable();
}
#MODULE_NAME=Ldap Sync

use lib '../libs';
use lib './libs';
use strict;
use Net::LDAP;
use ReadConfig;
use DBI;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "./config.yml");
$config->read_config;

### Some basic logging
open FILE, ">>/usr/local/www/helpdesk/modules/logfile";
print FILE "I ran " . localtime(time);
my $current = qx(pwd);
print FILE "\nCurrent working directory $current";
close(FILE);
################

### connect to ldap server
my $l = Net::LDAP->new($config->{'ldap_server'},port => $config->{'ldap_port'}, version => 3) or die "$@";
my $mesg = $l->bind($config->{'ldap_service_account'},password => $config->{'ldap_service_password'}) or die "$@";
my $result = $l->search(base => $config->{'base_dn'}, scope => "sub", filter => "(objectclass=person)") or die "$@";

my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";
my $query = "select count(*) from users where alias = ?";
my $sth = $dbh->prepare($query);
foreach my $entry ($result->entries)
{
	my $cn = $entry->get_value('cn');
	$sth->execute($cn);
	my $result = $sth->fetchrow_hashref;
	if($result->{'count'} == 0)
	{
		my $query = "select count(*) from customers where alias = ?";
		my $sth = $dbh->prepare($query);
		$sth->execute($cn);
		my $result = $sth->fetchrow_hashref;
		if($result->{'count'} == 0)
		{
			my $first = $entry->get_value('givenName');
			my $last = $entry->get_value('sn');
			my $email;
			if(defined($entry->get_value('mail'))){$email = $entry->get_value('mail');} #where AD stores the email address
			if(defined($entry->get_value('email'))){$email = $entry->get_value('email');} #where openLDAP stores the email address
			my $query = "insert into customers (first,last,email,alias) values ('$first','$last','$email','$cn')";
			my $sth = $dbh->prepare($query);
			$sth->execute;
		}
	}
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
	my $complete_path = $path . "/modules/ldap_sync.pl\n";

	open NEWCRON, ">>/tmp/opencop/" . $thisfile . "_schedule";
	print NEWCRON "* 23 * * * /usr/bin/env perl $complete_path";
	close NEWCRON;

	open FILE, ">>$file";
	print FILE "add:/tmp/opencop/" . $thisfile  . "_schedule\n";
	close(FILE);

	my $rmfile = "/tmp/opencop/" . $thisfile . "_schedule";
	qx(chmod 777 $file);
	qx(chmod 777 $rmfile);

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

	exit;
}
