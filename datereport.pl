#!/usr/bin/perl
use strict;
use warnings;
use lib "($ENV{'HOME'}/src/CCBOE/app/HTML--Template";

use CCBOEHD::DateReport;
my $cgiapp = new CCBOEHD::DateReport;
$cgiapp->run;

