#!/usr/bin/env perl
use strict;
use warnings;

my $cleanup_auth = "/usr/local/bin/cleanup_auth.pl";
my $file = "/tmp/opencop/opencop_crontab";
my $dir = "/tmp/opencop";
if(-d $dir){
	qx(chmod 770 $dir);
} else {
	qx(mkdir $dir);
	qx(chmod 770 $dir);
}

my $sleep_count = 0;

while(1){
	sleep(3);
	if(-e $file){
		my $rmfile;
		open FILE, "$file";
		foreach(<FILE>){
			if($_ =~ m/^add:/i){
				$_ =~ s/^add://i;
				my $newline = qx(cat $_);
				my $crontab = qx(crontab -l);
				chomp($crontab);
				my @crontab = split('\n',$crontab);
				push (@crontab,$newline);
				open NEW, ">>/tmp/opencop/newcron";
				foreach(@crontab){
					chomp($_);
					print NEW "$_\n";
				}
				close NEW;
			} elsif($_ =~ m/^remove:/i){
				my $crontab = qx(crontab -l);
				chomp($crontab);
				my @crontab = split('\n',$crontab);
				$_ =~ s/^remove://i;
				open NEW, ">>/tmp/opencop/newcron";
				foreach my $line (@crontab){
					chomp($line);
					chomp($_);
					if($line =~ m/$_/){
						
					} else {
						print NEW "$line\n";
					}
				}
				close NEW;
			}
		}
		close(FILE);
		qx(crontab /tmp/opencop/newcron);
		qx(rm -f $file);
		qx(rm -f /tmp/opencop/*.pl_schedule);
		qx(rm -f /tmp/opencop/newcron);
	}
	$sleep_count++;
	if(sleep_count > 20){
		qx(perl $cleanup_auth);
		$sleep_count = 0;
	}
}
