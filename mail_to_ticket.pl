# This script will download and remove all of the messages from the current mail server  for later processing

use strict;
use warnings;

use lib './libs';
use ReadConfig;
use Mail::IMAPClient;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $imap = Mail::IMAPClient->new(Server => $config->{'mail_server'},User => $config->{'ticket_mail_account'},Password => $config->{'ticket_mail_password'},Port => 993, SSL => 1) or die "IMAP Failure: $!";

#$imap->starttls() or die "Starttls failed in mail_to_ticket.pl"; #not needed right now but this does need to be an option in case the mail server only uses this

if($imap->exists("INBOX"))
{
        $imap->select("INBOX") or die "Select 'Inbox' error: ", $imap->LastError, "\n";
}
else
{
        die "Inbox doesn't exist\n";
}


my $msgcount = $imap->message_count("INBOX");
my @msgs = $imap->messages or die "Couldn't get all messages\n";

my $email_file = "tickets.mail";

open TICKETS, ">>$email_file" or die "Was not able to append to $email_file";

foreach my $msg (@msgs) {
	my $envelope = $imap->get_envelope($msg) or die "Could not get envelope: $@\n";
	my $sender = $envelope->sender_addresses or die "Could not get sender from envelope: $@\n";
	my $subject = $imap->subject($msg) or die "Could not get subject: $@\n";
	my $body = $imap->body_string($msg) or die "Could not get body string: $@\n";
	
        print TICKETS "Sender: $sender\n";
	print TICKETS "Subject: $subject\n";
	print TICKETS "Body: $body";
	print TICKETS "\n\$\$\$\n";
        $imap->delete_message(@msgs) or die "Couldn't delete message from server"; #Sets the Deleted flag
}

close(TICKETS);

$imap->expunge; #this removes messages that have the Deleted flag set

$imap->close("INBOX");

$imap->logout();
