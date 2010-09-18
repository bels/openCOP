use strict;
use warnings;

use lib './libs';
use ReadConfig;
use IMAP::Client;

my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $imap = new IMAP::Client($config->{'mail_server'};