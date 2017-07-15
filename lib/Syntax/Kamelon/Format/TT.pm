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
		$template = "No template set";
	}
	my $toolkit;
	if (defined $ttconfig) {
		$toolkit = Template->new($ttconfig)
	} else {
		$toolkit = Template->new()
	}
	unless (defined $wrap) { $wrap = 0 }
	unless (defined $outmet) { $outmet = "useget" }
	if ($outmet eq "useget") { $outmet = ref $self->{OUTPUT} }
	$self->{OUTMETHOD} = $outmet;
	$self->{TEMPLATE} = $template;
	$self->{TT} = $toolkit;
	$self->{WRAP} = $wrap;

	return $self;
}

sub Format {
	my $self = shift;
	my $outmet = $self->{OUTMETHOD};
	my $template = $self->{TEMPLATE};
	my $toolkit = $self->{TT};
	my $data = {
		folds => $self->{FOLDHASH},
		snippets => $self->{FORMATLIST},
	};
	$toolkit->process($template, $data, $outmet);
	return $self->SUPER->Get;
}

sub OutMethod {
	my $self = shift;
	if (@_) { $self->{OUTMETHOD} = shift }
	return $self->{OUTMETHOD}
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
