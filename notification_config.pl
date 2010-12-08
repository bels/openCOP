#!/usr/bin/env perl
use lib './libs';
use strict;
use warnings;
use CGI;
use URI::Escape;
use ReadConfig;
use DBI;
use SessionFunctions;
use UserFunctions;
use Data::Dumper;
use Template;
use YAML;

my $q = CGI->new();
my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");

$config->read_config;

my $session = SessionFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
my %cookie = $q->cookie('session');

my $authenticated = 0;

if(%cookie){
	$authenticated = $session->is_logged_in(auth_table => $config->{'auth_table'},id => $cookie{'id'},session_key => $cookie{'session_key'});
}

if($authenticated == 1){
	my $user = UserFunctions->new(db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},db_type => $config->{'db_type'});
	my $id = $session->get_id_for_session(auth_table => $config->{'auth_table'},id => $cookie{'id'});

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
	my @styles = ("styles/main.css","styles/notification_config.css");
	my @javascripts = ("javascripts/jquery.json-2.2.js","javascripts/jquery.validate.js","javascripts/main.js","javascripts/notification_config.js");
	my $meta_keywords = "";
	my $meta_description = "";
	my $file = "notification_config.tt";
	my $title = $config->{'company_name'} . " - Helpdesk Portal";
	my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'},logo => $config->{'logo_image'}, is_admin => $user->is_admin(id => $id), notify => $notification, fnotify => \%fnotification};
	
	print "Content-type: text/html\n\n";

	my $template = Template->new();
	$template->process($file,$vars) || die $template->error();
}
else{
	print $q->redirect(-URL => $config->{'index_page'});
}
