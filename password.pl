#!/usr/bin/env perl

use strict;
use warnings;
use CGI;
use DBI;
use lib './libs';
use ReadConfig;
use URI::Escape;
use Template;

#get the referrer so we know if we should display a internal page or a customer page.
my $q = CGI->new;
my $previous = $q->referer();
my $id = $q->param('id');
my $success = $q->param('success');
my $file;
my $customer;
my $type = uri_unescape($q->param('type'));
chomp $type;
warn $type;
if($previous =~ m/customer/i || $type eq "customer")
{
	$file = "customer_password.tt";
	$customer = 1;
}
my $config = ReadConfig->new(config_type =>'YAML',config_file => "config.yml");

$config->read_config;

my $meta_keywords = "";
my $meta_description = "";
my @styles = ("styles/layout.css", "styles/password.css");
my @javascripts = ("javascripts/jquery.js","javascripts/jquery.validate.js","javascripts/password.js");

my $title = $config->{'company_name'} . " - Helpdesk Portal";
my $vars = {'title' => $title,'styles' => \@styles,'javascripts' => \@javascripts,'keywords' => $meta_keywords,'description' => $meta_description, 'company_name' => $config->{'company_name'}, logo => $config->{'logo_image'},customer => $customer,id => $id, success => $success};
	
print "Content-type: text/html\n\n";

my $template = Template->new();
$template->process($file,$vars) || die $template->error();