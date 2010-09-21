# This script will process mail and turn it into a ticket.  It may do other things in the future but who knows.

use strict;
use warnings;

my $email_file = "tickets.mail";

open TICKETS, $email_file;

my @mail_data = <TICKETS>; #I am doing it this way so I can get the data out of the file quickly so the file can be blanked.

close(TICKETS);

open TICKETS, ">$email_file";
close(TICKETS); #file should be blank at this point

for