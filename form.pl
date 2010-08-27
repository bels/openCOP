#!/usr/bin/perl
use strict;
use warnings;
use lib "($ENV{'HOME'}/src/CCBOE/app/HTML--Template";

use CCBOEHD::Form;
my $cgiapp = new CCBOEHD::Form;
$cgiapp->run;

