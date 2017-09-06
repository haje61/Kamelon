package Syntax::Kamelon::Format::Base;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";
use Template;

my $default_template = <<__EOF;
[% IF lineoffset.defined ~%]
	[% linenum = lineoffset ~%]
	[% FOREACH line = content ~%]
		[% linenum  FILTER format('%03d ') ~%]
		[% FOREACH snippet = line ~%]
			[% snippet.tag %][% snippet.text %][% tagend ~%]
		[% END %][% newline ~%]
		[% linenum = linenum + 1 ~%]
	[% END ~%]
[% ELSE ~%]
	[% FOREACH line = content ~%]
		[% FOREACH snippet = line ~%]
			[% snippet.tag %][% snippet.text %][% tagend ~%]
		[% END %][% newline ~%]
	[% END ~%]
[% END ~%]
__EOF

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $engine = shift;
	my %args = (@_);

	my $data = delete $args{data};
	unless (defined $data) { $data = {} }

	my $folding = delete $args{folding};
	unless (defined $folding) { $folding = 0 }

	my $formattable = delete $args{format_table};
 	unless (defined($formattable)) { 
		my %sub = ();
		for ($engine->AvailableAttributes) {
			$sub{$_} = $_,
		}
		$formattable = \%sub
	}

	my $minfoldsize = delete $args{minfoldsize};
	unless (defined($minfoldsize)) { $minfoldsize = 1 }

	my $newline = delete $args{newline};
	unless (defined($newline)) { $newline = "\n" }

	my $notoolkit = delete $args{notoolkit};
	unless (defined $notoolkit) { $notoolkit = 0 }

	my $offset = delete $args{lineoffset};

	my $outmet = delete $args{outmethod};
	unless (defined $outmet) { $outmet = "returnscalar" }

	my $tagend = delete $args{tagend};
	unless (defined $tagend) { $tagend = '' }

	my $template = delete $args{template};
	unless (defined $template) { $template = \$default_template }

	my $textfilter = delete $args{textfilter};

	my $toolkit = delete $args{toolkit};
	my $ttconfig = delete $args{ttconfig};
	unless (defined $toolkit) {
		if (defined $ttconfig) {
			$toolkit = Template->new($ttconfig)
		} else {
			$toolkit = Template->new()
		}
	}

	my $self = {
		DATA => $data,
		ENGINE => $engine,
		FOLDING => $folding,
		LINES => [],
		FOLDS => {},
		FOLDSTACK => [],
   	FORMATTABLE => $formattable,
   	LINEOFFSET => $offset,
   	MINFOLDSIZE => $minfoldsize,
   	NEWLINE => $newline,
   	OUTMETHOD => $outmet,
		TAGEND => $tagend,
		TEMPLATE => $template,
		TT => $toolkit,
	};
	bless ($self, $class);
	$self->TextFilter($textfilter);

   return $self;
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

sub FoldEnd {
	my ($self, $region) = @_;
	my $eng = $self->{ENGINE};
	my $endline = $eng->LineNumber;
	my $stacktop = $self->FoldStackTop;
	my $folding = $self->{FOLDING};
	if (($folding eq 'all') or ($self->FoldStackLevel <= $folding)) {
		if (($endline - $stacktop->{start}) >= $self->{MINFOLDSIZE}) {
			my $beginline = delete $stacktop->{start};
			$stacktop->{end} = $endline;
			$stacktop->{depth} = $self->FoldStackLevel;
			$self->{FOLDS}->{$beginline} = $stacktop;
		}
	}
	$self->FoldStackPull;
}

sub Folds {
	my $self = shift;
	return $self->{FOLDS};
}

sub Folding {
	my $self = shift;
	if (@_) {
		my $f = shift;
		my $cf = $self->{FOLDING};
		if (($f ne $cf) and (($f eq 0) or ($cf eq 0))){
			$self->{FOLDING} = $f;
			$self->{ENGINE}->ClearLexers;
		}
	}
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

# sub Format {
# 	my $self = shift;
# 	my $res = '';
# 	my $lines = $self->{LINES};
# 	while (@$lines) {
# 		my $snippets = shift @$lines;
# 		while (@$snippets) {
# 			my $f = shift @$snippets;
# 			my $t = shift @$snippets;
# 			my $s = $self->{SUBSTITUTIONS};
# 			my $rr = '';
# 			my @string = split //, $f;
# 			while (@string) {
# 				my $k = shift @string;
# 				if (exists $s->{$k}) {
# 						$rr = $rr . $s->{$k}
# 				} else {
# 					$rr = $rr . $k;
# 				}
# 
# 			}
# 			$res = $res . $t->[0] . $rr . $t->[1];
# 		}
# 		$res = $res . $self->{NEWLINE};
# 	}
# 	return $res
# }

sub Format {
	my $self = shift;
	my $out = '';
	my $outmet = $self->{OUTMETHOD};
	if ($outmet eq 'returnscalar') {
		$outmet = \$out
	}
	my $template = $self->{TEMPLATE};
	my $toolkit = $self->{TT};
	$toolkit->process($template, $self->GetData, $outmet)  || do {
		my $error = $toolkit->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $out
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

sub GetData {
	my $self = shift;
	my $dt = $self->{DATA};
	my %data = (%$dt,
		folds => $self->{FOLDS},
		content => $self->{LINES},
		lineoffset => $self->{LINEOFFSET},
		newline => $self->{NEWLINE},
		tagend => $self->{TAGEND},
	);
	return \%data;
}

sub Lines {
	my $self = shift;
	return $self->{LINES}
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
		my $text = shift;
		my $call = $self->{PREPROCESSOR};
		$text = &$call($self, $text);
		my %tok = (
			text => $text,
			tag => shift,
		);
		push @line, \%tok
	}
	my $fl = $self->{LINES};
	push @$fl, \@line
}

# sub Parse {
# 	my $self = shift;
# 	my $list = $self->{LINES};
# 	push @$list, \@_;
# }

sub PreProcessOff {
	my ($self, $text) = @_;
	return $text
}

sub PreProcessOn {
	my ($self, $t) = @_;
	my $tk = $self->{TT};
	my $text = '';
	my $filt = $self->{TEXTFILTER};
	$tk->process(\$filt, { text => $t }, \$text)  || do {
		my $error = $tk->error();
		print STDERR "error type: ", $error->type(), "\n";
		print STDERR "error info: ", $error->info(), "\n";
		print STDERR $error, "\n";
	};
	return $text
}

sub Reset {
	my $self = shift;
	$self->{FOLDS} = {};
	$self->{FOLDSTACK} = [];
	$self->{LINES} = [];
}

sub TagEnd {
	my $self = shift;
	if (@_) { $self->{TAGEND} = shift }
	return $self->{TAGEND}
}

sub Template {
	my $self = shift;
	if (@_) { $self->{TEMPLATE} = shift }
	return $self->{TEMPLATE}
}

sub TextFilter {
	my $self = shift;
	if (@_) {
		my $filt = shift;
		if (defined $filt) {
			$self->{PREPROCESSOR} = $self->can('PreProcessOn')
		} else {
			$self->{PREPROCESSOR} = $self->can('PreProcessOff')
		}
		$self->{TEXTFILTER} = $filt
	}
	return $self->{TEXTFILTER}
}

sub Toolkit {
	my $self = shift;
	if (@_) { $self->{TOOLKIT} = shift }
	return $self->{TOOLKIT}
}

1;
__END__
