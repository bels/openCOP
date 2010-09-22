# This script will process mail and turn it into a ticket.  It may do other things in the future but who knows.

use strict;
use warnings;
use lib './libs';
use Ticket;
use ReadConfig;

my $email_file = "tickets.mail";

open TICKETS, $email_file;

my @mail_data = <TICKETS>; #I am doing it this way so I can get the data out of the file quickly so the file can be blanked.

close(TICKETS);

open TICKETS, ">$email_file";
close(TICKETS); #file should be blank at this point

my $new_message = 0;
my $sender = "";
my $subject = "";
my $body = "";

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");
$config->read_config; #I am doing this because we have to call submit on the ticket object directly instead of letting ticket.pl handle it.  This means that we have to pass in the database information

my $ticket = Ticket->new(mode => "new");

for my $line (@mail_data)
{

	if($line =~ /Return-Path:\s+<(.+@.+)>/)
	{
		$sender = $1;
	}
	if($line =~ /Subject:\s+(.*)/)
	{
		$subject = $1;
	}
	if($line !~ /.+:/) #theory is all header lines start with something: or something-else: where the body doesn't.  So unless someone starts the message something: we should be good.  This is a hack for now.
	{
		$body = $body . " $line";
	}
	
	if($line =~ /\$\$\$/)
	{
		$new_message = 1;
	}
	
	if($new_message == 1)
	{
		$body =~ s/\$\$\$//;
		my $data = {site => "",barcode => "",location =>"",author => $sender,contact => $sender,troubelshoot=> "",section=>"",problem=>$body,priority =>"Normal",serial=>"",email=>$sender}; #This part will need to be improved.  Right now I am leaving a lot of fields blank that with some investigation could be filled out.  For example, I won't know what site someone is sending the ticket in from
								#unless I lookup in the database for a matching email address and then checking what site that person is at.  Also, the persons name could be looked up by email address.  This is something that isn't feasible now but should be in the future
		#$ticket->submit(db_type => $config->{'db_type'},db_name=> $config->{'db_name'},user =>$config->{'db_user'},password => $config->{'db_password'},data => $data);
		open LOG, ">>log.txt";
		print LOG "$sender\n";
		print LOG "$subject\n";
		print LOG "$body\n\n";
		close LOG;
		$subject = "";
		$sender = "";
		$body = "";
		$new_message = 0;
	}
}
