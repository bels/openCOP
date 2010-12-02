#!/usr/bin/env perl

use strict;
use warnings;

my @diskio;
my @mem;

my $mem = qx(which sysctl);
my $iostat = qx(which iostat);
chomp($mem);
chomp($iostat);

my @drives = split(/\n/,qx(df -h));
my @scratch = split(/\n/,qx(uptime));
if($mem){
	@mem = split(/\n/,qx(sysctl -a | grep Memory));
}
if($iostat){
	@diskio = split(/\n/,qx(iostat -d));
}
my @temp = split(/\,/,$scratch[0]);
my @load = ($temp[3],$temp[4],$temp[5]);
#thresholds
my $disk_threshold = 75;
my $mem_threshold = 75;
my $load_threshold = .75;
my $diskio_threshold = 2;

print "Content-type: text/html\n\n";

my $i = 0;
my $class;
foreach (@drives)
{
	if($i == 0)
	{
		$class = "data_title";
	}
	else
	{
		$class = "";
	}
	print qq(<div class="server_data_row">);
	$_ =~ s/ +/ /g;
	my $j = 0;
	foreach(split(/\s/,$_)){
		if($_ eq "Mounted")
		{
			print qq(<span class="$class drive_data">$_ On);
		}elsif($_ eq "on"){
		}else{
			print qq(<span class="$class drive_data">$_);
		}
		
		if($j == 4 && $i != 0)
		{
			chop($_);
			if($_ > $disk_threshold)
			{
				print qq( <img src="images/bad.png">);
			}else{
				print qq( <img src="images/good.png">);
			}
		}
		print "</span>";
		$j++;
	}
	print qq(</div>);
	$i++;
}
$i = 0;
foreach (@mem)
{
	print qq(<div class="server_data_row">);
	$_ =~ s/\t+/\t/g;
	$i = 0;
	foreach(split(/\t/,$_)){
		if($i == 0)
		{
			$class = "data_title";
		}
		else
		{
			$class = "";
		}
		print qq(<span class="$class memory_data">$_</span>);
		$i++;
	}
	print qq(</div>);
}
print qq(<div class="server_data_row">);
print qq(<span class="data_title load_data">CPU Load Averages</span><br/>);
$i = 0;
foreach (@load)
{
	if($i == 0){
		my @temp = split(/:/, $_);
		if(defined($temp[1])){
			print qq(<span class="load_data">1 Minute: $temp[1]);
			if($temp[1] > $load_threshold)
			{
				print qq( <img src="images/bad.png">);
			}else{
				print qq( <img src="images/good.png">);
			}
		}
	}
	if($i == 1){
		if(defined($_)){
			print qq(<span class="load_data">5 Minute: $_);
			if($_ > $load_threshold)
			{
				print qq( <img src="images/bad.png">);
			}else{
				print qq( <img src="images/good.png">);
			}
		}
	}
	if($i == 2){
		if(defined($_)){
			print qq(<span class="load_data">15 Minute: $_);
			if($_ > $load_threshold)
			{
				print qq( <img src="images/bad.png">);
			}else{
				print qq( <img src="images/good.png">);
			}
		}
	}
	print "</span>";
	$i++;
}
print qq(</div>);
$i = 0;
foreach (@diskio)
{
	if($i == 0)
	{
		$class = "data_title diskio_title";
	}
	else
	{
		$class = "diskio_data";
	}
	print qq(<div class="server_data_row">);
	$_ =~ s/ +/ /g;
	$_ =~ s/^\s//;
	my $j = 0;
	foreach(split(/\s/,$_)){
		print qq(<span class="$class ">$_);
		
		if(($j == 2 || $j == 5 || $j == 8) && $i != 0 && $i != 1)
		{
			chop($_);
			if($_ > $diskio_threshold)
			{
				print qq( <img src="images/bad.png">);
			}else{
				print qq( <img src="images/good.png">);
			}
		}
		print "</span>";
		$j++;
	}
	print qq(</div>);
	$i++;
}
