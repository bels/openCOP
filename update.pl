#!/usr/bin/env perl

use strict;
use warnings;
use lib './libs';
use ReadConfig;
use Updater;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "/usr/local/etc/opencop/config.yml");
$config->read_config;

my $updater = 
