#!/usr/local/bin/perl

use lib './CCBOEHD';
use strict;
use CGI;
use URI::Escape;
use SessionFunctions;
use Digest::MD5 qw(md5_hex);

my $q = CGI->new(); #create CGI
my $alias = uri_unescape($q->param('username')); #getting the username from the form
my $password = uri_unescape($q->param('password')); #getting the password from the form

chomp($alias);
chomp($password);
#CHANGE THIS NEXT LINE.  THE DATABASE SHOULD BE READ FROM CONFIG FILE
my $session = SessionFunctions->new(database=> 'ccboehd',user =>'helpdesk',password => 'helpdesk') or die "Couldn't connect to the database";

my $success = $session->authenticate_user(alias => $alias, password => $password);

if($success)
{
	my $session_key = md5_hex(localtime);

	my $session_id = $session->create_session_id(session_key => $session_key, uid => $alias) or die "Creating the session in the database failed";
	my $cookie = $q->cookie(-name=>'session',-value=>{'sid' => $session_id,'session_key' => $session_key},-expires=>'+1h') or die "Creating the cookie failed";

	print $q->redirect(-cookie=>$cookie,-URL=>"main.html");
}
else
{
	my $errorpage = "error.pl?errorcode=1";
	print $q->redirect(-URL=>$errorpage);
}
