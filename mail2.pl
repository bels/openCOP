#!/usr/bin/perl

use Data::Dumper;

  use Mail::SendEasy ;

  my $mail = new Mail::SendEasy(
  smtp => 'exchange.ccboe.com' ,
  user => 'cbuehler',
  pass => &encode_base64('c001n3ss'),
  auth => 'LOGIN',
  ) ;
  
  my $status = $mail->send(
  from    => 'cbuehler@ccboe.com' ,
  from_title => 'subject line' ,
  reply   => 'cbuehler@ccboe.com', # The reply-to address, in case it's not the same as from
  error   => 'error@foo.com' ,
  to      => 'sorpigal@gmail.com' ,
  cc      => 'cbuehler@ccboe.com' ,
  subject => "MAIL Test" ,
  msg     => "The Plain Msg..." ,
  html    => "<b>The HTML Msg...</b>" ,
  msgid   => "0101" ,
  ) ;
  
  if (!$status) { print $mail->error ; die Data::Dumper::Dumper $mail}


    sub encode_base64
{
    my $res = "";
    my $eol = $_[1];
    $eol = "\n" unless defined $eol;
    pos($_[0]) = 0;                          # ensure start at the beginning
    while ($_[0] =~ /(.{1,45})/gs) {
	$res .= substr(pack('u', $1), 1);
	chop($res);
    }
    $res =~ tr|` -_|AA-Za-z0-9+/|;               # `# help emacs
    # fix padding at the end
    my $padding = (3 - length($_[0]) % 3) % 3;
    $res =~ s/.{$padding}$/'=' x $padding/e if $padding;
    # break encoded string into lines of no more than 76 characters each
    if (length $eol) {
	$res =~ s/(.{1,76})/$1$eol/g;
    }
    $res;
}
