package Syntax::Kamelon::Format::TT;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use base qw(Syntax::Kamelon::Format::Base);
use Template;

sub new {
   my $class = shift;
   my $engine = shift;
   my %args = (@_);

   my $outmet = delete $args{outmethod};
   my $template = delete $args{template};
	my $toolkit = delete $args{toolkit};
	my $ttconfig = delete $args{ttconfig};

	my $self = $class->SUPER::new($engine, %args);

	unless (defined $toolkit) {
		if (defined $ttconfig) {
			$toolkit = Template->new($ttconfig)
		} else {
			$toolkit = Template->new()
		}
	}
	unless (defined $outmet) { $outmet = "returnscalar" }
	$self->{OUTMETHOD} = $outmet;
	$self->{TEMPLATE} = $template;
	$self->{TT} = $toolkit;

	return $self;
}

sub Format {
	my $self = shift;
	my $out = '';
	my $output;
	my $outmet = $self->{OUTMETHOD};
	if ($outmet eq 'returnscalar') {
		$output = \$out
	} else {
		$output = $outmet
	}
	my $template = $self->{TEMPLATE};
	my $toolkit = $self->{TT};
	$toolkit->process($template, $self->GetData, $output)  || do {
		my $error = $toolkit->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $out
}

sub GetData {
	my $self = shift;
	return {
		folds => $self->{FOLDS},
		content => $self->{LINES},
	}
}

sub OutMethod {
	my $self = shift;
	if (@_) { $self->{OUTMETHOD} = shift }
	return $self->{OUTMETHOD}
}

sub Parse {
	my $self = shift;
	my @line = ();
	while (@_) {
		my %tok = (
			text => shift,
			tag => shift,
		);
		push @line, \%tok
	}
	my $fl = $self->{LINES};
	push @$fl, \@line
}

sub Template {
	my $self = shift;
	if (@_) { $self->{TEMPLATE} = shift }
	return $self->{TEMPLATE}
}

1;
__END__
