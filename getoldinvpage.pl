#!/usr/bin/perl

use strict;
use LWP::Simple;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Request::Common;
use HTTP::Headers;
use CGI;

my $q = new CGI;

my $barcode = $q->param('barcode');
my $field = $q->param('field');
#$barcode = '8990';

my $UA = LWP::UserAgent->new(agent => "Kill-O-Mat/1.0", timeout => 60);
$UA->cookie_jar({file => "cookie.txt"});

my $oldinvpage = "http://10.82.0.20/eqlookup.php";
my $Page = $UA->get($oldinvpage."?Eqid=$barcode", referer => "http://helpdesk.ccboe.com/helpdesk");

print "Content-type: text/xml\n\n";

if($Page->code == 200){
	# Got it
	$Page->content =~ /$field.*value="(.*)"/;
	my $value = $1;
	print qq(<?xml version="1.0" standalone="yes"?>\n);
	print qq(<oldinv>\n);
	print qq( <field name="$field">$value</field>\n);
	print qq(</oldinv>\n);
} else{
	# Error
	print qq(<?xml version="1.0" standalone="yes"?>\n);
	print qq(<oldinv>\n);
	print qq( <field name="$field">Error ).$Page->code.qq(</field>\n);
	print qq(</oldinv>\n);
	# Return a document with $Page->code as the error msg
}



__END__
<br>Serial Number:  <input name="serial_num" type="text" size="20" value="KCDD4$">
