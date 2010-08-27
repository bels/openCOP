#!/usr/bin/perl
# A brutish import script to get data from a tab delimited file which was exported from the old access database

use strict;
sub toggle(\$);
sub read_field_headers();
use DBI;
my $dbh = DBI->connect('dbi:mysql:ccboehd;host=localhost','collin','helpdesk',
			{'RaiseError'=>1,'AutoCommit'=>1},
                     );
        if(!$dbh){
                die ": mayday mayday\n";
        }



my $file = shift || die 'no file specified';
open(DB,$file) or die $!;
my @db = <DB>;
close(DB) or die $!;
my $db = join('',@db);
my @imported;
my $str = '';
my $field = 0;
my @row;
my $escaped = 0;
my $quoted = 0;
my $last = \$str;
my $i = 0;
# Maybe this part should merely convert the big flat file into an array of record globs. So, it should essentially split on non-quoted 
# newlines. Then we can do more field splitting with a later loop.
print STDERR "Processing records...";
foreach my $c (split(//,$db)){
	if($c eq '\\'){
		toggle($escaped);
	} elsif($$last eq '\\' && $escaped){
		$escaped = 0;
	}
	if($c eq '"' and !$escaped){
#		warn " TOGGLE QUOTE ". ($quoted?"OFF":"ON")."\n";
		toggle($quoted);
#		$str .= $c;
	} elsif($c eq '"' and $escaped){
		$str .= $c;
	} elsif($c eq "\n"){
		if(!$quoted){
#			warn " END OF RECORD $i \n";
			# end record
			$i++;
			push(@imported,$str);
#			print $i.': '.$str."\n";
			$str = '';
		} else{
			$str .= $c;
		}
	} else{
		$str .= $c;
	}
	#warn "QUOTE\n" if $c eq '"';
	$last = \$c;
}

sub toggle(\$){
#warn "Q: ".${$_[0]};
#exit;
	if(${$_[0]} == 1){
		${$_[0]} = 0;
	} else{
		${$_[0]} = 1;
	}
}

print STDERR " done\n";

#field labels, in order:
#Ticket	School	Contact	Requested Date	Recieved By	Problem	Notes	Completed Date	Time Spent	Done?	In For Repair?	Location	Priority	Status	Equipment ID	Contact Phone	Troubleshooting	Troubleshot By Pickup Date	Picked Up By	Tested Logon	Tested Printing	Tested Antivirus	Date Completed	Completed By	Date Returned	Delivered By
my @labels = read_field_headers();
my @old;
print STDERR "Converting TSV into hash for each record...";
my $k;
for($k=0;$k<@imported;$k++){
die if $k > 50000;
	my @f = split(/\t/,$imported[$k]);
	my %v;
	for (my $o=0;$o<@labels;$o++){
		$v{$labels[$o]} = $f[$o];
	}
	push(@old,\%v);
#	push(@old,{$labels[$o] => $f[$o]});
}
print STDERR " $k conversions.\n";
#
# NOW we can begin! $old[0] = a hash of the first old record, and so on.
#

print STDERR "Converting hash of old-labeled into hash with current DB labels";
my @final;
foreach my $o (@old){
	my %h;
#print keys %{$o};
#die;
	foreach my $k (keys (%{$o})){
		if($k eq 'Ticket'){
			$h{'ticket'} = $o->{$k}; 
		} elsif($k eq 'School'){
			$h{'school'} = $o->{$k};
		} elsif($k eq 'Contact'){
			$h{'contact'} = $o->{$k};
		} elsif($k eq 'Requested Date'){
			# **must** Wrap some date/time stuff around this
			my ($d,$t) = split(' ', $o->{$k});
			my @mdy = split('/',$d);
			$h{'requested'} = join('-',$mdy[2],$mdy[0],$mdy[1]).' '.$t;
		} elsif($k eq 'Problem'){
			$h{'problem'} = $o->{$k};
		} elsif($k eq 'Notes'){
			$h{'notes'} = $o->{$k};
		} elsif($k eq 'Completed Date'){
			$h{'updated'} = $h{'requested'};
		} elsif($k eq 'Done?'){
			if($o->{'Done?'}){
				$h{'status'} = 4;
			} else{
				$h{'status'} = 1;
			}
		} elsif($k eq 'In For Repair?' && $o->{$k}){
			unless($o->{'Done?'}){
				$h{'status'} = 2;
			}
		} elsif($k eq 'Location'){
			$h{'location'} = $o->{$k};
		} elsif($k eq 'Priority'){
			$h{'priority'} = 3;
		} elsif($k eq 'Equipment ID'){
			$h{'barcode'} = $o->{$k};
		} elsif($k eq 'Contact Phone'){
			$h{'contact_phone'} = $o->{$k};
		} elsif($k eq 'Troubleshooting'){
			$h{'troubleshot'} = $o->{$k};
		} elsif($k eq 'Recieved By'){
			$h{'tech'} = $o->{$k};
		} else{
#			warn " ($o->{'Ticket'}) $k: $o->{$k}\n";
		}
	}
	push(@final,\%h);
}
#die $final[10000]->{'ticket'};
print STDERR " ".scalar(@final). " loops\n";

sub quote($){
#	return "\"$_\"";
	return $dbh->quote($_);
}

print STDERR "Assembling SQL!...";
my @sql;
foreach my $r (@final){
	my @keys = keys %{$r};
	my @vals = values %{$r};
#die map { '"'.quote($r->{$_}).'"' } @keys;
#	print join('',@vals);
	push(@sql, 'insert into helpdesk ('.(join(',',@keys)).') values ('.(join(',',map { quote($r->{$_}) } @vals)).');');
}
print STDERR " Done (".scalar(@sql)." records)\n";

#print "\n\n\n";
print STDERR  "Printing SQL\n";
#print join("\n",@sql);
foreach my $s (@sql){
	$dbh->do($s);
#	print $s."\n";
}


sub read_field_headers(){
	my $file = "fields";
	open(FH,"$file") or die $!;
	my $line1 = <FH>;
	close(FH) or die $!;
	chomp($line1);
	my @f = split(/\t/,$line1);
	return @f;
}

__END__

my @labels  = qw(ticket);
my @records;
my $j = 0;
foreach my $record (@imported){
	foreach my $column (@{$record}){
		next unless($labels[$j]);
		$hash{$labels[$j]} = $column;
		$j++;
	}
	push(@records,\%hash);
}

foreach my $r (@records){
	print $r->{'ticket'}."\n";
}
