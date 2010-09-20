# This script will download and remove all of the messages from the current mail server  for later processing

use strict;
use warnings;

use lib './libs';
use ReadConfig;
use Mail::IMAPClient;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $imap = Mail::IMAPClient->new(Server => $config->{'mail_server'},User => $config->{'ticket_mail_account'},Password => $config->{'password'},Port => 443, SSL => 0);

$imap->starttls() or die "Starttls failed in mail_to_ticket.pl";

$imap->select("INBOX") or die "Select 'Inbox' error: ", $imap->LastError, "\n";

my @msgs = $imap->search('ALL') or die "Couldn't get all messages\n";

my $email_file = "tickets.mail";

open TICKETS, ">>$email_file" or die "Was not able to append to $email_file";

foreach my $msg (@msgs) {
	$imap->message_to_file(TICKETS, $msg);
	$imap->delete_message($msg) or die "Couldn't delete message from server"; #Sets the Deleted flag
}

close(TICKETS);

$imap->expunge; #this removes messages that have the Deleted flag set

$imap->close("INBOX");

$imap->logout();
