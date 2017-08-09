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

	my $foldbegincall = delete $args{foldbegincall};
	my $foldendcall = delete $args{foldendcall};
	my $folding = delete $args{folding};
	my $formattable = delete $args{format_table};
	my $newline = delete $args{newline};
	my $substitutions = delete $args{substitutions};
	unless (defined $foldbegincall) { $foldbegincall = sub {} }
	unless (defined $foldendcall) { $foldendcall = sub {} }
	unless (defined $folding) { $folding = 0 }
 	unless (defined($formattable)) { 
		my %sub = ();
		for ($engine->AvailableAttributes) {
			$sub{$_} = $_,
		}
		$formattable = \%sub
	}
	unless (defined($newline)) { $newline = "\n" }
	unless (defined($substitutions)) { $substitutions = {} }
	my $self = {
		ENGINE => $engine,
		FOLDING => $folding,
		FORMATLIST => [],
		OUTPUT => '',
		FOLDBEGINCALL => $foldbegincall,
		FOLDENDCALL => $foldendcall,
		FOLDHASH => {},
		FOLDSTACK => [],
   	FORMATTABLE => $formattable,
   	NEWLINE => $newline,
		SUBSTITUTIONS => $substitutions,
	};
   bless ($self, $class);
   return $self;
}

sub Clear {
	my $self = shift;
	$self->{OUTPUT} = '';
}

sub FoldBegin {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	chomp(my $line = $eng->CurrentLine);
	my %op = (
		start => $eng->LineNumber, 
		region => $region, 
		line => $line
	);
	$self->FoldStackPush(\%op);
}

sub FoldBeginCall {
	my $self = shift;
	if (@_) { $self->{FOLDBEGINCALL} = shift; }
	return $self->{FOLDBEGINCALL};
}

sub FoldEnd {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	my $endline = $eng->LineNumber;
	my $stacktop = $self->FoldStackTop;
	my $folding = $self->{FOLDING};
	if (($folding eq 'all') or ($self->FoldStackLevel <= $folding)) {
		if ($endline > $stacktop->{start}) {
			my $beginline = delete $stacktop->{start};
			$stacktop->{end} = $endline;
			$stacktop->{depth} = $self->FoldStackLevel;
			$self->{FOLDHASH}->{$beginline} = $stacktop;
		}
	}
	$self->FoldStackPull;
}

sub FoldEndCall {
	my $self = shift;
	if (@_) { $self->{FOLDENDCALL} = shift; }
	return $self->{FOLDENDCALL};
}

sub FoldHash {
	my $self = shift;
	return $self->{FOLDHASH};
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
	unshift @$stack, shift;
}

sub FoldStackTop {
	my $self = shift;
	my $stack = $self->{FOLDSTACK};
	return $stack->[0]
}

sub Format {
	my $self = shift;
	my $res = '';
	my $lines = $self->{FORMATLIST};
	while (@$lines) {
		my $snippets = shift @$lines;
		while (@$snippets) {
			my $f = shift @$snippets;
			my $t = shift @$snippets;
	# 		unless (defined($t)) { 
	# 			$t = $self->FormatTable('Normal') 
	# 		}
			my $s = $self->{SUBSTITUTIONS};
			my $rr = '';
			my @string = split //, $f;
			while (@string) {
				my $k = shift @string;
				if (exists $s->{$k}) {
						$rr = $rr . $s->{$k}
				} else {
					$rr = $rr . $k;
				}

			}
			$res = $res . $t->[0] . $rr . $t->[1];
		}
		$res = $res . $self->{NEWLINE};
	}
	return $res
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

# sub Get {
# 	my $self = shift;
# 	my $a = $self->{OUTPUT};
# 	$self->{OUTPUT} = '';
# 	return $a;
# }

sub Parse {
	my $self = shift;
	my $list = $self->{FORMATLIST};
	push @$list, \@_;
}

sub Reset {
	my $self = shift;
	$self->{FOLDHASH} = {};
	$self->{FOLDSTACK} = [];
	$self->{FORMATLIST} = [];
	$self->{OUTPUT} = '';
}

sub Substitutions {
	my $self = shift;
	return $self->{SUBSTITUTIONS}
}

1;
__END__
