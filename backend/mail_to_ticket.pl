#!/usr/local/bin/perl
# This script will download and remove all of the messages from the current mail server  for later processing

use strict;
use warnings;

use YAML::XS;
use Mail::IMAPClient;
use DBI;
use Courriel;
use Data::Dumper;

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

my $dbh = DBI->connect("dbi:Pg:dbname=" . $config->{'ticket_db'},$config->{'db_username'},$config->{'db_user_password'},{AutoCommit => 1});

my $sql =<<SQL;
insert into ticket.ticket(status,author,priority,contact,contact_email,synopsis,problem,submitter,section) values 
	((select id from ticket.status where status = 'New'),'Email',(select id from ticket.priority where description = 'Normal'),?,?,?,?,(select id from auth.users where first = 'Admin'),(select id from ticket.section where name = 'Helpdesk'))
SQL

my $sth = $dbh->prepare($sql);
foreach my $msg (@msgs) {
	my $raw = $imap->message_string($msg) or die $imap->LastError;
	my $email = Courriel->parse(text => $raw);

	my $sender = $email->from();
	## kinda a hack cause I'm not sure the proper way to achieve what I'm doing with this module is
	my $body = $email->html_body_part();
	$body = $email->plan_body_part() unless defined $body;
	## end hack
	$sth->execute($sender->address,$sender->address,$email->subject(),$body->content());


    my $new_msg = $imap->move($processed_folder,$msg) or die "Could not move: $@\n";
    $imap->expunge;
}

$imap->close($inbox);

$imap->logout();

sub walk_parts {
    my ($obj, $callback) = @_;
    if ($obj->is_multipart) {
        for my $part ($obj->parts) {
            walk_parts($part, $callback);
        }
    } else {
        $callback->($obj);
    }
}

1;