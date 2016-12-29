#!/usr/local/bin/perl
# This script will process mail and turn it into a ticket.  It may do other things in the future but who knows.

use strict;
use warnings;
use lib './libs';
use Ticket;
use ReadConfig;
use DBI;
use MIME::Parser;
use MIME::Entity;
use MIME::Body;

my (@body, $i, $subentity);
my $parser = new MIME::Parser;

#new attachment code start
#these are the types of attachments allowed
my @attypes= qw(application/msword
                application/pdf
                application/gzip
                application/tar
                application/tgz
                application/zip
                audio/alaw-basic
                audio/vox
                audio/wav
                image/bmp
                image/gif
                image/jpeg
                text/html
                text/plain
                text/vxml
);
my ($x, $newx, @attachment, $attachment, @attname, $bh, $nooatt);
#new attachement code end

$parser->ignore_errors(1);
$parser->output_to_core(1);

my $email_file = "tickets.mail";
open TICKETS, $email_file;

#my    $entity = $parser->parse_data(<TICKETS>);
my $tickets;

foreach(<TICKETS>){
	if($_ =~ m/^------.*?\n+/){
	#	$_ =~ s/^------.*?\n+/--------------\n/;
		$tickets .= $_;
	} elsif($_ =~ m/Content-Type/){
	#	$_ .= qq( boundary="--------------";);
		$tickets .= $_;
	} else {
		$tickets .= $_;
	}
}
#warn $tickets;
bless(\$tickets);
my $entity = $parser->parse(\$tickets);
#my $entity = $parser->parse_open($email_f);
my $error = ($@ || $parser->last_error);
warn $error;
#close(TICKETS);



#my @mail_data = <TICKETS>; #I am doing it this way so I can get the data out of the file quickly so the file can be blanked.


#open TICKETS, ">$email_file";
#close(TICKETS); #file should be blank at this point

my $new_message = 0;
my $from = "";
my $to = "";
my $subject = "";
my $body = "";

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config; #I am doing this because we have to call submit on the ticket object directly instead of letting ticket.pl handle it.  This means that we have to pass in the database information

my $ticket = Ticket->new(mode => "new");

#open LOG, ">>log.txt";

#get email headers
my $header = $entity->head;
$subject = $header->get('Subject');
$to = $header->get('To');
$from = $header->get('From');

chomp($subject);
chomp($to);
chomp($from);

#get email body
if ($entity->parts > 0){
    for ($i=0; $i<$entity->parts; $i++){
        
        $subentity = $entity->parts($i);
        
        if (($subentity->mime_type =~ m/text\/html/i) || ($subentity->mime_type =~ m/text\/plain/i)){
            $body = join "",  @{$subentity->body};
            #new attachment code start
            next;
            #new attachment code end
        }
        
        #this elsif is needed for Outlook's nasty multipart/alternative messages
        elsif ($subentity->mime_type =~ m/multipart\/alternative/i){

            $body = join "",  @{$subentity->body};
            
            #split html and text parts
            @body = split /------=_NextPart_\S*\n/, $body;
            
            #assign the first part of the message,
            #hopefully the text, part as the body
            $body = $body[1]; 
            
            #remove leading headers from body
            $body =~ s/^Content-Type.*Content-Transfer-Encoding.*?\n+//is;
            #new attachment code start
            next;
            #new attachment code end
        }

        #new attachment code start
        #grab attachment name and contents
        foreach $x (@attypes){
            if ($subentity->mime_type =~ m/$x/i){
                $bh = $subentity->bodyhandle;
                $attachment = $bh->as_string;
                push @attachment, $attachment;
                push @attname, $subentity->head->mime_attr('content-disposition.filename');
            }else{
                #some clients send attachments as application/x-type.
                #checks for that
                $newx = $x;
                $newx =~ s/application\/(.*)/application\/x-$1/i;
                if ($subentity->mime_type =~ m/$newx/i){
                    $bh = $subentity->bodyhandle;
                    $attachment = $bh->as_string;
                    push @attachment, $attachment;
                    push @attname, $subentity->head->mime_attr('content-disposition.filename');
                }
            }
            
        }
        $nooatt = $#attachment + 1;
        #new attachment code end
    }
} else {
   $body = join "",  @{$entity->body};
}

#body may contain html tags. they will be stripped here
$body =~ s/(<br>)|(<p>)/\n/gi;           #create new lines
$body =~ s/<.+\n*.*?>//g;                #remove all <> html tages
$body =~ s/(\n|\r|(\n\r)|(\r\n)){3,}//g; #remove any extra new lines
$body =~ s/\&nbsp;//g;                   #remove html &nbsp characters

#remove trailing whitespace from body
$body =~ s/\s*\n+$//s;

#open MAIL, ("|/usr/sbin/sendmail -t") || die "Unable to send mail: $!";
#print MAIL "To: $from\n";
#print MAIL "From: root\n";
#print MAIL "Subject: mime parser test\n\n";

#print MAIL "Messege was contructed as follows:
#\$from:    $from
#\$to:      $to
#\$subject: $subject

#\$body:    $body
#number of attachments: $nooatt
#\$attachment(s): ".join ", ", @attname;
#close MAIL;

#new attachment code start
#write contents of each attachment to a file
for ($x = 0; $x < $nooatt; $x++){
    open FH, ">/tmp/attachments/$attname[$x]" || die "cannot open FH: $!\n";
    print FH "$attachment[$x]";
    close FH;
}
#new attachment code end
#close LOG;
