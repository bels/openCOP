#!/usr/bin/perl
# need to be sure to check that schools being accessed are not marked DELETED
package CCBOEHD::ManageSchools;
use base qw(CCBOEHD::Base);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;

##
## Overides
##

sub setup
{
	my $self = shift;
	
	$self->start_mode('view');
	$self->mode_param('mode');
	$self->run_modes(
		'view' => 'view_schools',
		'update' => 'update_schools',
		'add' => 'add_schools',
	);
	$self->db_connect;
}

sub hddb_print
{
	my $self = shift;
	# Load template, perform substitutions...
	my $html = "<html><body>\n";
	$html .= join('',@_) if @_;
	$html .= "</body></html>";
	return $html;
}

##
## Interface
##

sub view_schools{
	my $self = shift;

	return $self->hddb_print($self->make_school_form());
}	

sub update_schools{
	my $self = shift;
	# mode=update
	# primaryteam=possibly new TEAM_NUMBER
	# secondaryteam=possbly new TEAM_NUMBER
	# number=SCHOOL_NUMBER
	# level=possibly new SCHOOL_LEVEL
	# name=possibly new name
	return $self->hddb_print("update, no act");
}

sub add_schools{
	my $self = shift;
	return $self->hddb_print("add, no act");
}

##
## Internal functions 
##

sub school_update_assignment{
	my $self = shift;
	my($scid,$tid,$assignment) = @_;

	my $update_it = $self->param('hddb')->prepare("select $assignment from school_team_assignment where scid=$scid;");
	$update_it->execute();
	my ($existing_assignment) = $update_it->fetchrow_array();
	if($existing_assignment){
		# Exists, update
		# "update team (tid,assignment) set values ($tid,$assignment) where scid = $scid;";
	} else{
		# Does not exist, insert
		# "insert into team (scid,tid,assignment) values ($scid,$tid,$assignment;";
	}

#	"update schools set (level,name,deleted) to values("$level,$name,$del") where scid = $scid";
#	"update school_team_assignment (tid,assignment) to values("$tid,$assignment") where scid = $scid;"

}

sub update_or_insert{
#	my $self = shift;
#	my($field,$table,$column,$value);
#	my $sth = $self->param('hddb')->prepare("select * from $table where $column='$value';");
#	$sth->execute();
#	if($sth->fetchrow_array()){
#		return 'update';
#	} else{
#		return 'insert';
#	}
}

#        if(&update_or_insert($uid,'uid','scores') eq 'update'){
#                $dbh->do("update scores set score = score + $gained where uid = \"$uid\";");
#        } else{
#                $dbh->do("insert into scores(uid,score,tid) values(\"$uid\",\"$gained\",\"$tid\");");
#        }


#        my $sth = $dbh->prepare("select u.uid,u.username,s.ans,s.gained,s.score,s.tid ".
#                                "from recent_scores as s ".
#                                "inner join users as u on u.uid = s.uid ".
#                                "where tid != s.uid order by score desc limit $max;");

#        $sth->execute();
#        while(my($id,$name,$ans,$gained,$score,$tid) = $sth->fetchrow_array()){


sub school_selector{
	my $self = shift;
	my $selected = shift;
	my $sortby = shift;
	if($sortby){
		$sortby = "order by $sortby";
	} else{
		$sortby = "order by slid";
	}
	if(defined($selected)){
		$selected = $selected;
	} else{
		$selected = -1;
	}
	my $sth = $self->param('hddb')->prepare("select slid,type from school_level $sortby;");
	$sth->execute();

	my $select = qq(<select name="level">\n);
	while(my ($slid,$desc) = $sth->fetchrow_array()){
		if($slid == $selected){
			$select .= qq(<option value="$slid" selected="true">$desc</option>\n);
		} else{
			$select .= qq(<option value="$slid">$desc</option>\n);
		}
	}
	$select .= qq(</select>\n);
	return $select;
}

sub team_selector{
	my $self = shift;
	my $named = shift; # what the field will be name='d
	my $selected = shift;
	my $sortby = shift;
	if($sortby){
		$sortby = "order by $sortby";
	} else{
		$sortby = "order by name";
	}
	if(defined($selected)){
		$selected = $selected;
	} else{
		$selected = -1;
	}
	unless(defined($named)){
		$named = 'team';
	}
	my $sth = $self->param('hddb')->prepare("select tid,name from team where deleted != 1 $sortby;");
	$sth->execute();
	my $select = qq(<select name="$named">\n);
	while(my ($tid,$name) = $sth->fetchrow_array()){
		if($tid == $selected){
			$select .= qq(<option value="$tid" selected="true">$name</option>\n);
		} else{
			$select .= qq(<option value="$tid">$name</option>\n);
		}
	}
	$select .= qq(</select>\n);
	return $select;
}

sub make_school_field{
	my $self = shift;
	my $id = shift;
	my $type = shift;
	my $name = shift;
	my $html = 	qq( School number ).
#			qq(<input type="text" name="number" value="$id" size="5" />). # Eventually maybe put this back in
			qq($id <input type="hidden" name="number" value="$id" />\n).
			qq( is named ).
			qq(<input type="text" name="name" value="$name" size="10" />\n).
			qq( and is a ).($self->school_selector($type));
	return $html;
}

# Using make_school_field() and school_selector(), output HTML page for updaing school information
sub make_school_form{
	my $self = shift;
	my $sth = $self->param('hddb')->prepare("select scid,level,name from school where 1 order by name;");
	$sth->execute();

	my $html = qq(<form name="update_schools" method="post" action=").$self->query->url().qq(">);
	$html .= qq(<input type="hidden" name="mode" value="update" />\n);
	while(my ($scid,$level,$name) = $sth->fetchrow_array()){
		$html .= $self->make_school_field($scid,$level,$name);
		# HERE SHOULD BE: 
#school_team_assignment
#| scid       | int(11) |      | PRI | 0       |       |
#| tid        | int(11) |      | PRI | 0       |       |
#| assignment
#select a.scid,a.tid,a.assignment,s.name from school_team_assignment as a left join team 
#as t on t.tid = a.tid inner join school as s on s.scid = a.scid where t.deleted != 1;

#my $asgnh = $self->param('hddb')->prepare("select a.scid,a.tid,a.assignment,s.name from 
#school_team_assignment as a left join team as t on t.tid = a.tid inner join school as s 
#on s.scid = a.scid where 1;");
#"select tid from school_team_assignment where scid = $scid;")
		my $asgnh = $self->param('hddb')->prepare("select tid from school_team_assignment where scid = $scid and assignment = 1;");
		$asgnh->execute();
		my ($psel) = ($asgnh->fetchrow_array());
		$asgnh = $self->param('hddb')->prepare("select tid from school_team_assignment where scid = $scid and assignment = 2;");
		$asgnh->execute();
		my ($ssel) = ($asgnh->fetchrow_array());
		$html .= qq( and is primarily serviced by ).
			 $self->team_selector('primaryteam',$psel).
			 qq( and secondarily by ).
			 $self->team_selector('secondaryteam',$ssel);
		$html .= "<br />\n";
	}
	$html .= qq(<input type="submit" value="Update Information" />);
	$html .= qq(</form>\n);

	$html .= qq(<form name="add_school" method="post" action=").$self->query->url().qq(">).
			qq(<input type="hidden" name="mode" value="add" />\n).
			qq( Add a school with number ).
			qq(<input type="text" name="number" value="" size="5" />).
			qq( named ).
			qq(<input type="text" name="name" value="" />\n).
			qq( and make it a ).$self->school_selector(-1).qq(\n);
	$html .= qq(<input type="submit" value="Add" />);
	$html .= qq(</form);
	$html .= qq(\n);
	return $html;
}



1;
