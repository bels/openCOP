use strict;
use warnings;

use lib './libs';
use ReadConfig;
use Mail::IMAPClient;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $imap = Mail::IMAPClient->new(Server => $config->{'mail_server'},User => $config->{'ticket_mail_account'},Password => $config->{'password'},Port => 443, SSL => 0);

$imap->starttls() or die "Starttls failed in mail_to_ticket.pl";

