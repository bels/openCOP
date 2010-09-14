#!/usr/bin/env perl
use CGI;
use CGI::Carp qw/:fatalsToBrowser/;

use warnings;
use strict;
use Date::Manip qw/UnixDate/;
#use Data::Dumper;

my $q = new CGI;
print $q->header;

#my $date = ParseDate("5/25/2005");
#print Data::Dumper::Dumper $date;
#print UnixDate($date,"%s");
#print "\n";
print UnixDate("6/30/2005","%s")||time;
