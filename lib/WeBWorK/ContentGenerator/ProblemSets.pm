################################################################################
# WeBWorK mod_perl (c) 1995-2002 WeBWorK Team, Univeristy of Rochester
# $Id$
################################################################################

package WeBWorK::ContentGenerator::ProblemSets;

=head1 NAME

WeBWorK::ContentGenerator::ProblemSets - Display a list of built problem sets.

=cut

use strict;
use warnings;
use base qw(WeBWorK::ContentGenerator);
use Apache::Constants qw(:common);
use CGI qw();
use WeBWorK::ContentGenerator;
use WeBWorK::DB::WW;
use WeBWorK::Utils qw(formatDateTime);

sub initialize {
	my $self = shift;
	my $courseEnvironment = $self->{courseEnvironment};
	
	# Open a database connection that we can use for the rest of
	# the content generation.
	
	my $wwdb = new WeBWorK::DB::WW $courseEnvironment;
	$self->{wwdb} = $wwdb;
}

sub path {
	my ($self, $args) = @_;
	
	my $ce = $self->{courseEnvironment};
	my $root = $ce->{webworkURLs}->{root};
	my $courseName = $ce->{courseName};
	return $self->pathMacro($args,
		"Home" => "$root",
		$courseName => "",
	);
}

sub title {
	my $self = shift;
	my $courseEnvironment = $self->{courseEnvironment};
	
	return $courseEnvironment->{courseName};
}

sub body {
	my $self = shift;
	my $r = $self->{r};
	my $courseEnvironment = $self->{courseEnvironment};
	my $user = $r->param('user');
	my $wwdb = $self->{wwdb};
	
	print CGI::startform(-method=>"POST", -action=>$r->uri."/hardcopy");
	print CGI::start_table();
	print CGI::Tr(
		CGI::th("Sel."),
		CGI::th("Name"),
		CGI::th("Status"),
		CGI::th("Hardcopy"),
	);
	
	my @sets;
	push @sets, $wwdb->getSet($user, $_) foreach ($wwdb->getSets($user));
	foreach my $set (sort { $a->open_date <=> $b->open_date } @sets) {
		print $self->setListRow($set);
	}
	
	print CGI::end_table();
	print $self->hidden_authen_fields;
	print CGI::p(CGI::submit("hardcopy", "Download Harcopy for Selected Sets"));
	print CGI::endform();
	
	return "";
}

sub setListRow($$) {
	my $self = shift;
	my $set = shift;
	
	my $name = $set->id;
	
	my $interactiveURL = "set$name/?" . $self->url_authen_args;
	my $hardcopyURL = "hardcopy/set$name/?" . $self->url_authen_args;
	
	my $openDate = formatDateTime($set->open_date);
	my $dueDate = formatDateTime($set->due_date);
	my $answerDate = formatDateTime($set->answer_date);
	
	my $checkbox = CGI::checkbox(-name=>"set", -value=>$set->id, -label=>"");
	my $interactive = CGI::a({-href=>$interactiveURL}, $name);
	my $hardcopy = CGI::a({-href=>$hardcopyURL}, "download hardcopy");
	
	my $status;
	if (time < $set->open_date) {
		$status = "opens at $openDate";
		$checkbox = "";
		$interactive = $name;
		$hardcopy = "";
	} elsif (time < $set->due_date) {
		$status = "open, due at $dueDate";
	} elsif (time < $set->answer_date) {
		$status = "closed, answers at $answerDate";
	} else {
		$status = "closed, answers available";
	}
	
	return CGI::Tr(CGI::td([
		$checkbox,
		$interactive,
		$status,
		$hardcopy,
	]));
}

1;
