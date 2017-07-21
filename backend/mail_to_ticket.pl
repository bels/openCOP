#!/usr/local/bin/perl
# This script will download and remove all of the messages from the current mail server  for later processing

use strict;
use warnings;

use YAML::XS;
use Mail::IMAPClient;
use DBI;

my $config_file = './conf/config.yml';

my $config = YAML::XS::LoadFile($config_file);

my $imap = Mail::IMAPClient->new(Server => $config->{'mail_server'},User => $config->{'helpdesk_account'},Password => $config->{'helpdesk_password'},Port => $config->{'port'}, Ssl => $config->{'ssl'}, Uid => $config->{'uid'}) or die "IMAP Failure: $!";

my $inbox = $config->{'mail_inbox_folder'};
if($imap->exists($inbox))
{
        $imap->select($inbox) or die "Select $inbox error: ", $imap->LastError, "\n";
}
else
{
        die "$inbox doesn't exist\n";
}


my $msgcount = $imap->message_count($inbox);
my @msgs = $imap->messages or die "Couldn't get all messages\n";

my $processed_folder = $config->{'mail_processed_folder'};

my $dbh = DBI->connect("dbi:Pg:dbname=" . $config->{'ticket_db'},$config->{'db_username'},$config->{'db_user_password'},{AutoCommit => });

my $sql =<<SQL;
insert into ticket.ticket(status,author,priority,contact_email,synopsis,problem,submitter) values 
	((select id from ticket.status where status = 'New'),'Email',(select id from ticket.priority where description = 'Normal'),?,?,?,(select id from auth.users where first = 'Admin'))
SQL

my $sth = $dbh->prepare($sql);
foreach my $msg (@msgs) {
	my $envelope = $imap->get_envelope($msg) or die "Could not get envelope: $@\n";
	my $sender = $envelope->sender_addresses or die "Could not get sender from envelope: $@\n";
	my $subject = $imap->subject($msg) or die "Could not get subject: $@\n";
	my $body = $imap->body_string($msg) or die "Could not get body string: $@\n";
	
	$sth->execute($sender,$subject,$body);

    #$msg = $imap->move($processed_folder,$msg) or die "Could not move: $@\n";
    #$imap->expunge;
}


$imap->close($inbox);

$imap->logout();

1;