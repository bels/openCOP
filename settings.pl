#!/usr/local/bin/perl

use strict;
use Template;
use lib './libs';
use CGI;
use ReadConfig;
use SessionFunctions;
use UserFunctions;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my $q = CGI->new();
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie)
{
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1)
{
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

	sub sort_hash_list($){
		my $hashref = shift;
		my @list;
		foreach(keys %$hashref){
			push(@list,$_);
		}
		my @array = sort({lc($a) cmp lc($b)} @list);
		return @array;
	}

	my $i;
	my $dbh = DBI->connect("dbi:$config->{'db_type'}:dbname=$config->{'db_name'}",$config->{'db_user'},$config->{'db_password'}, {pg_enable_utf8 => 1})  or die "Database connection failed in $0";

	## Site levels
	my $query = "select id,type from site_level where not deleted";
	my $sth = $dbh->prepare($query);
	$sth->execute;
	my $site_levels = $sth->fetchall_hashref('type');
	my @site_levels = sort_hash_list($site_levels);

	## Sites
	$query = "select id,name from site where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $sites = $sth->fetchall_hashref('name');
	my @sites = sort_hash_list($sites);

	## Companies
	$query = "select id,name from company where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $companies = $sth->fetchall_hashref('name');
	my @companies = sort_hash_list($companies);

	## Sections
	$query = "select id,name from section where not deleted";
	$sth = $dbh->prepare($query);
	$sth->execute;
	my $sections = $sth->fetchall_hashref('name');
	my @sections = sort_hash_list($sections);

	my $success = $q->param('success');
	my $section_success = $q->param('section_success');
	my $duplicate = $q->param('duplicate');
	my $level_success = $q->param('level_success');
	my $company_success = $q->param('company_success');
	my $delete_company_success = $q->param('delete_company_success');
	my $associate_success = $q->param('associate_success');
	my $delete_site_success = $q->param('delete_site_success');
	my $delete_site_level_success = $q->param('delete_site_level_success');
	
	my @styles = ( "styles/settings.css");
	my @javascripts = ("javascripts/jquery.json-2.2.js","javascripts/main.js","javascripts/jquery.validate.js","javascripts/settings.js");
	my $meta_keywords = "";
	my $meta_description = "";

	my %fnotification = (
		'mail_server'		=>	"Mail Server",
		'sending_server'	=>	"Sending Server",
		'email_user'		=>	"SMTP Authentication User",
		'email_password'	=>	"SMTP Authentication Password",
		'from'			=>	"Address to be sent from",
		'ticket_create'		=>	"Message to be sent when a new ticket is input",
		'ticket_update'		=>	"Message to be sent when a ticket is updated",
		'ticket_close'		=>	"Message to be sent when a ticket is closed",
		'notify_tech'		=>	"Message sent to a technician when they are assigned a ticket",
		'company_name'		=>	"Company Name",
		'new_user'		=>	"Message sent to a new user on creation",
		'send_attachment'	=>	"Message to display when emailing a report",
	);
	my $notification = YAML::LoadFile("/usr/local/etc/opencop/notification.yml");

	my $file = "settings.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {
		'title'				=>	$title,
		'styles'			=>	\@styles,
		'javascripts'			=>	\@javascripts,
		'keywords'			=>	$meta_keywords,
		'description'			=>	$meta_description,
		'company_name'			=>	$config->{'company_name'},
		logo				=>	$config->{'logo_image'},
		success				=>	$success,
		level_success			=>	$level_success,
		company_success			=>	$company_success,
		site_levels			=>	$site_levels,
		sites				=>	$sites,
		sections			=>	$sections,
		companies			=>	$companies,
		site_level_list			=>	\@site_levels,
		sites_list			=>	\@sites,
		section_list			=>	\@sections,
		company_list			=>	\@companies,
		associate_success		=>	$associate_success,
		delete_site_success		=>	$delete_site_success,
		delete_site_level_success	=>	$delete_site_level_success,
		is_admin			=>	$user->is_admin(id => $id),
		notify				=>	$notification, 
		fnotify				=>	\%fnotification,
		duplicate			=>	$duplicate,
		section_success	=> $section_success
	};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else
{
	print $q->redirect(-URL => $config->{'index_page'});
}
