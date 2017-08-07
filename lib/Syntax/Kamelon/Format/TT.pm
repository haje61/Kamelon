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
	my $ttconfig = delete $args{ttconfig};
	my $wrap = delete $args{wrap};

	my @attr = $engine->AvailableAttributes;
	my %attrhash = ();
	for (@attr) {
		$attrhash{$_} = $_;
	}
	$args{format_table} = \%attrhash;
	my $self = $class->SUPER::new($engine, %args);

	unless (defined $template) {
		die "No template file set";
	}
	unless (-e $template) { die "template file does not exist" }
	my $toolkit;
	if (defined $ttconfig) {
		$toolkit = Template->new($ttconfig)
	} else {
		$toolkit = Template->new()
	}
	unless (defined $wrap) { $wrap = 0 }
	unless (defined $outmet) { $outmet = "returnscalar" }
	$self->{OUTMETHOD} = $outmet;
	$self->{TEMPLATE} = $template;
	$self->{TT} = $toolkit;
	$self->{WRAP} = $wrap;

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
	my $data = {
		folds => $self->{FOLDHASH},
		content => $self->{FORMATLIST},
	};
	$toolkit->process($template, $data, $output)  || do {
		my $error = $toolkit->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $out
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
	my $fl = $self->{FORMATLIST};
	push @$fl, \@line
}

sub Template {
	my $self = shift;
	if (@_) { $self->{TEMPLATE} = shift }
	return $self->{TEMPLATE}
}

sub Wrap {
	my $self = shift;
	if (@_) { $self->{WRAP} = shift }
	return $self->{WRAP}
}


1;
__END__
