package Syntax::Kamelon::Format::Base;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $engine = shift;
	my %args = (@_);

	my $foldbeginpostcall = delete $args{foldbeginpostcall};
	my $foldbeginprecall = delete $args{foldbeginprecall};
	my $foldendpostcall = delete $args{foldendpostcall};
	my $foldendprecall = delete $args{foldendprecall};
	my $folding = delete $args{folding};
	my $formattable = delete $args{format_table};
	my $substitutions = delete $args{substitutions};
	unless (defined $foldbeginpostcall) { $foldbeginpostcall = sub {} }
	unless (defined $foldbeginprecall) { $foldbeginprecall = sub {} }
	unless (defined $foldendpostcall) { $foldendpostcall = sub {} }
	unless (defined $foldendprecall) { $foldendpostcall = sub {} }
	unless (defined $folding) { $folding = 0 }
 	unless (defined($formattable)) { 
		my %sub = ();
		for ($engine->AvailableAttributes) {
			$sub{$_} = $_
		}
		$formattable = \%sub
	}
	unless (defined($substitutions)) { $substitutions = {} }
	my $self = {
		ENGINE => $engine,
		FOLDING => $folding,
		OUTPUT => '',
		FOLDBEGINPOSTCALL => $foldbeginpostcall,
		FOLDBEGINPRECALL => $foldbeginprecall,
		FOLDENDPOSTCALL => $foldendpostcall,
		FOLDENDPRECALL => $foldendprecall,
		FOLDSTACK => [],
   	FORMATTABLE => $formattable,
		SUBSTITUTIONS => $substitutions,
	};
   bless ($self, $class);
   return $self;
}

sub Clear {
	my $self = shift;
	$self->{OUTPUT} = '';
}

sub FoldBeginPost {
	my ($self, $region) = @_;
	my $call = $self->{FOLDBEGINPOSTCALL};
	&$call($region);
}

sub FoldBeginPre {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	my @op = ($region, $eng->LineNumber, $eng->CurrentLine);
	$self->FoldStackPush(@op);
	my $call = $self->{FOLDBEGINPRECALL};
	&$call($region);
}

sub FoldBeginPostCall {
	my $self = shift;
	if (@_) { $self->{FOLDBEGINPOSTCALL} = shift; }
	return $self->{FOLDBEGINPOSTCALL};
}

sub FoldBeginPreCall {
	my $self = shift;
	if (@_) { $self->{FOLDBEGINPRECALL} = shift; }
	return $self->{FOLDBEGINPRECALL};
}

sub FoldEndPost {
	my ($self, $region) = @_;
	my $call = $self->{FOLDENDPOSTCALL};
	&$call($region);
	$self->FoldStackPull;
}

sub FoldEndPre {
	my ($self, $region) = @_;
	my $call = $self->{FOLDENDPRECALL};
	&$call($region);
}

sub FoldEndPostCall {
	my $self = shift;
	if (@_) { $self->{FOLDENDPOSTCALL} = shift; }
	return $self->{FOLDENDPOSTCALL};
}

sub FoldEndPreCall {
	my $self = shift;
	if (@_) { $self->{FOLDENDPRECALL} = shift; }
	return $self->{FOLDENDPRECALL};
}

sub Folding {
	my $self = shift;
	return $self->{FOLDING};
}

sub FoldStackLevel {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	my $size = @$stack;
	return $size
}

sub FoldStackPull {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	return shift @$stack
}

sub FoldStackPush {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	unshift @$stack, \@_
}

sub FoldStackTop {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	return $stack->[0]
}

sub Format {
	my $self = shift;
	my $res = '';
	while (@_) {
		my $f = shift;
		my $t = shift;
		unless (defined($t)) { 
			$t = $self->FormatTable('Normal') 
		}
		my $s = $self->{SUBSTITUTIONS};
		my $rr = '';
		while ($f ne '') {
			my $k = substr($f , 0, 1);
			$f = substr($f, 1, length($f) -1);
			if (exists $s->{$k}) {
				 $rr = $rr . $s->{$k}
			} else {
				$rr = $rr . $k;
			}
		}
		my @tags = @$t;
		$res = $res . $t->[0] . $rr . $t->[1];
	}
	$self->{OUTPUT} = $self->{OUTPUT} . $res
}

sub FormatTable {
	my $self = shift;
	my $key = shift;
	if (defined $key) {
		my $t = $self->{FORMATTABLE};
		if (@_) { $t->{$key} = shift; }
		if (exists $t->{$key}) {
			return $t->{$key};
		}
	}
	return undef
}

sub Get {
	my $self = shift;
	my $a = $self->{OUTPUT};
	$self->{OUTPUT} = '';
	return $a;
}

sub Substitutions {
	my $self = shift;
	return $self->{SUBSTITUTIONS}
}

1;
__END__
