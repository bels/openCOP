#!/usr/bin/perl

package CCBOEHD::ManageTeams;
use base qw(CCBOEHD::Base);

use strict;
use warnings;

use CGI::Carp qw(fatalsToBrowser);

use DBI;
use CGI;
use HTML::Template;

our $hddb;

##
## Overrides
##

sub setup
{
	my $self = shift;
	
	$self->param('template' => HTML::Template->new(
		filename => 'manage-teams-view.html',
		path => [
			'/home/collin/src/CCBOE/app/HTML--Template/templates',
			'/home/collin/src/CCBOE/app/templates',
		],
	));

	$self->param('template')->param('query_url' => $self->query->url);

	$self->start_mode('manage');
	$self->mode_param('mode');
	$self->run_modes(
		'manage' => 'team_manage',
		'update' => 'team_update',
		'add'	=> 'team_add',
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
## Interface functions
## 

sub team_manage{
	my $self = shift;
	$self->team_manage_form();
	return  $self->param('template')->output;
}


sub team_update{
	my $self = shift;
	my %form = $self->form_to_variables();
	my ($rnstr,$delstr) = $self->interpret_team_changes(%form);
	$self->team_manage_form();
	$self->param('template')->param('manage_team_messages' => "We $rnstr and then we $delstr.");
	return $self->param('template')->output;
}


sub team_add{
	my $self = shift;
	my @name = $self->query->param();
	my %form = $self->form_to_variables();
	my $rc = $self->new_team_named($form{'newteam'});
	if($rc){ # $rc is the new TID if set
		$self->param('template')->param('manage_team_messages' => qq(Created team $rc named $form{'newteam'}).$self->team_manage_form());
		return $self->param('template')->output;
	} else{
		$self->param('template')->param('manage_team_messages' => qq(There was a problem creating the new team. Nothing done.));
		return $self->param('template')->output;
	}
}


## 
## Internal functions
## 

sub tid_name_to_field{
	my $self = shift;
	my($tid,$name,$delchecked) = @_;
	if(defined($tid) && defined($name)){
		my $un;
		if($delchecked){
			$delchecked = ' <b>inactive</b>';
			$un = 'un';
		} else{
			$delchecked = '';
			$un = '';
		}
		my $html;
		$html .= qq(Change$delchecked team $tid\'s name from <i>$name</i> to );
		$html .= qq(<input type="text" name="newname$tid" value="" /> );
		$html .= qq(or ).$un.qq(delete it <input type="checkbox" name=").$un.qq(delete$tid" />);
		$html .= qq(<br />);
		return qq(<div id="manage_team_current_field">).$html.qq(</div>);
	} else{
		die "$self: tid_name_to_field: mayday mayday, tid and name not true\n";
	}
}

sub team_manage_form{
	my $self = shift;
	my $sth = $self->param('hddb')->prepare("select tid,name,deleted from team where 1 group by deleted,tid,name;");
	$sth->execute();
	my $cgi = $self->query;
	my $manage_team_current = '';
	$manage_team_current .= qq(<input type="hidden" name="mode" value="update" />\n);
	while(my ($tid,$name,$del) = $sth->fetchrow_array()){
		$manage_team_current .= $self->tid_name_to_field($tid,$name,$del)."\n";
	}
	$manage_team_current .= qq(<input type="submit" name="update" value=Update names" />\n);

	my $manage_team_add = '';
	$manage_team_add .= qq(<input type="hidden" name="mode" value="add" />);
	$manage_team_add .= qq(Enter new team name:\n<input type="text" name="newteam" value="" /> );
	$manage_team_add .= qq(<input type="submit" name="add" value="Create new team" />\n);

	$self->param('template')->param('manage_team_update_form' => $manage_team_current);
	$self->param('template')->param('manage_team_add_form' => $manage_team_add);

	return 1;
}

# This takes the CGI FORM hash, which conatains all form fields. Only 
# for when team renaming form submitted.
sub interpret_team_changes{
	my $self = shift;
	my %form = @_;
	my %change;
	my %delete;
	foreach my $name (keys %form){
		my $tid = $name =~ /(\d+)/;
		$tid = $1 if defined $1;
		if($name =~ /^newname/){
			if($form{$name} and $tid){
				$change{$tid} = $form{$name};
			}
		} elsif($name =~ /^undelete/){
			$delete{$tid} = 0;
		} elsif($name =~ /^delete/){
			$delete{$tid} = 1;
		}
	}
	my $delstr = $self->delete_teams(%delete);
	my $rnstr = $self->rename_teams(%change);
	return ($delstr,$rnstr);
}

sub delete_teams{
	my $self = shift;
	my %team = @_;
	my @actions;
	my $action = 'deleted';
	my $sth = $self->param('hddb')->prepare("update team set deleted = ? where tid = ?;");
	foreach my $tid (keys %team){
		$sth->execute($team{$tid},$tid);
		if($team{$tid}){
			$action = 'deleted';
		} else{
			$action = 'active';
		}
		push(@actions,"marked team $tid as $action");
	}
	if(@actions){
		return join(', ',@actions);
	} else{
		return "deleted no teams";
	}
}

sub rename_teams{
	my $self = shift;
	my %newname = @_;

	my @actions;
#	my $sth = $self->param('hddb')->prepare("update team set name='?' where tid=?;");
	foreach my $tid (keys %newname){
		# update team set name = '$newname{$tid}' where tid = $tid;
#		my $tmp = $newname{$tid};
#		$sth->execute($tmp,$tid);
		$self->param('hddb')->do("update team set name='$newname{$tid}' where tid=$tid;");
		push(@actions,"renamed team $tid to $newname{$tid}");
	}
	if(@actions){
		return join(', ',@actions);
	} else{
		return "renamed no teams";
	}
}

sub new_team_named{
	my $self = shift;
	my $name = shift;
	my $sth = $self->param('hddb')->prepare("insert into team (name,deleted) values('$name',1);");
	$sth->execute();
	$sth = $self->param('hddb')->prepare("select tid from team where name = '$name';");
	$sth->execute();
	my @tid = $sth->fetchrow_array();
	if(@tid){
		return shift @tid; # tnew teamID means it worked
	} else{
		return 0; #  zero for error
	}
}


1;
