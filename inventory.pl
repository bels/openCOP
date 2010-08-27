#!/usr/bin/perl
use strict;
use warnings;
use lib "($ENV{'HOME'}/src/CCBOE/app/HTML--Template";

use CCBOEHD::Inventory;
my $cgiapp = new CCBOEHD::Inventory;
$cgiapp->run;

