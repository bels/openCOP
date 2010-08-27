#!/usr/bin/perl
use strict;
use warnings;
use lib "($ENV{'HOME'}/src/CCBOE/app/HTML--Template";

use CCBOEHD::Report;
my $cgiapp = new CCBOEHD::Report;
$cgiapp->run;

