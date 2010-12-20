#!/usr/bin/env perl
if($ARGV[0] eq "enable")
{
	enable();
}
if($ARGV[0] eq "disable")
{
	disable();
}
#MODULE_NAME=Ldap Auth
use lib '../libs';
use lib './libs';
use strict;
use Net::LDAP;
use ReadConfig;
use CGI;
use YAML;



my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config;

my $q = CGI->new(); #create CGI
my $alias = uri_unescape($q->param('username')); #getting the username from the form
my $password = uri_unescape($q->param('password')); #getting the password from the form
chomp($alias);
chomp($password);

### connect to ldap server
my $l = Net::LDAP->new($config->{'ldap_server'},port => $config->{'ldap_port'}, version => 3) or die "$@";
my $mesg = $l->bind($config->{'ldap_service_account'},password => $config->{'ldap_service_password'}) or die "$@";
my $result = $l->search(base => $config->{'base_dn'}, scope => "sub", filter => "(objectclass=top)");

### loops over all the results checking to see what the dn is of the username entered
my $dn;
foreach my $entry ($result->entries)
{
	if(defined($config->{'directory_type'})){
		if($config->{'directory_type'} =~ m/AD/i)
		{
			my $sam = $entry->get_value('sAMAccountName'); #this more than likely is the same as the login name for Active Directory because of legacy stuff
			if($sam eq $alias)
			{
				$dn = $entry->dn();
			}
		} elsif($config->{'directory_type'} =~ m/eDirectory/i){
			my $cn = $entry->get_value('cn'); #eDirectory looks to use cn as the login name
			if($cn eq $alias)
			{
				$dn = $entry->dn();
			}
		} else {
			my $login = $entry->get_value($config->{'directory_login_attribute'}); #this should be for other ldap directory servers.  Hopefully those admins know what attribute is used for logins
			if($login eq $alias)
			{
				$dn = $entry->dn();
			}
		}
	} else {
		warn "Config is screwed.  Missing ldap information";
	}
}

$l->unbind();
$mesg = $l->bind($dn,password => $password) or die "$@";

if($mesg->code() == 0)
{
	qx(authenticate.pl username=$alias password=$password);
}
else
{
	my $errorpage = "index.pl?errorcode=1";
	print $q->redirect(-URL=>$errorpage);
}

sub enable{
	my $config;
	if (-e "/usr/local/etc/opencop/config.yml")
	{
		$config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");
	}
	else
	{
		die "Config file (/usr/local/etc/opencop/config.yml) does not exist or the permissions on it are not correct.\n";
	}
	
	$config->{'backend'} = 'ldap';
	YAML::DumpFile('/usr/local/etc/opencop/config.yml', $config);
	exit;
}

sub disable{
	my $config;
	if (-e "/usr/local/etc/opencop/config.yml")
	{
		$config = YAML::LoadFile("/usr/local/etc/opencop/config.yml");
	}
	else
	{
		die "Config file (/usr/local/etc/opencop/config.yml) does not exist or the permissions on it are not correct.\n";
	}
	
	$config->{'backend'} = 'database';
	YAML::DumpFile('/usr/local/etc/opencop/config.yml', $config);
	exit;
}
