#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Template;

my $q = new CGI;
print $q->header;

sub load_tips(){
	open(TIPS,"tips.data") or die "$!";
	my %tip;
	while(<TIPS>){
		chomp;
		my($id,$str) = split(/\t/,$_);
		$tip{$id} = $str;
	}
#	print $tip{'100'};
#	print values %tip;
	return %tip;
}

sub get_tip($){
	my $tipid = shift;
	my %tips = load_tips();
#die  $tips{$tipid};
	return $tips{$tipid};
}

sub print_tip($){
	my $tipstr = shift;
	print $tipstr;
return;
	print <<EOHTML
<html>
 <head>
  <style type="text/css">
   #tip{
    background- color:#aa00aa;
   }
  </style>
  <title> Information </title>
 </head>
 <body>
  <div id="tip">
   $tipstr
  </div>
 </body>
EOHTML
;
	return 1;
}

my $tip = get_tip($q->param('keywords'));
if(!$tip){
	print "Whoops\n".($q->param);
} else{
	print_tip($tip);
}

