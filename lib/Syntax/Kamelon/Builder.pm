package Syntax::Kamelon::Builder;

our $VERSION = '0.01';

use strict;
use Carp qw(cluck);
use Data::Dumper;

use base qw(Syntax::Kamelon::XMLData);

my $regchars = "\\^.\$|()[]{}*+?~!%^&/";


sub new {
	my $class = shift;
	my %args = (@_);
	
	my $engine = delete $args{engine};

   my $self = $class->SUPER::new(%args);

   $self->{CURCONTEXT} = '';
   $self->{CURRULE} = '';
   $self->{DELIMINATORS} = '';
	$self->{ENGINE} = $engine;
	if (defined $self->FileName) {
		return $self->Setup;
	}
	return undef;
}

sub AttributeGet {
	my ($self, $attribute) = @_;
	if (exists $self->{ATTRIBUTES}->{$attribute}) {
		return $self->{ATTRIBUTES}->{$attribute}
	} 
	if (exists $self->ContextData->{$self->CurContext}->{attribute}) {
		$self->LogWarning("Undefined attribute '$attribute', reverting to context attribute");
		$attribute = $self->ContextData->{$self->CurContext}->{attribute};
		if (exists $self->{ATTRIBUTES}->{$attribute}) {
			return $self->{ATTRIBUTES}->{$attribute}
		} 
	} 
	$self->LogWarning("Undefined attribute '$attribute', reverting to 'Normal'");
	return 'Normal'
}

sub AttributeGetF {
	my ($self, $attribute, $ctx) = @_;
	my $token = $self->AttributeGet($attribute);
	my $eng = $self->{ENGINE};
	my $a = $eng->FormatTable($token);
	unless (defined $a) {
		$a = $eng->FormatTable('Normal');
		$self->LogWarning("Undefined Format token '$token', for '$attribute' reverting to 'Normal'");
	}
	return $a
}

sub ContextExists {
	my ($self, $context) = @_;
	return (exists $self->{CONTEXTDATA}->{$context}) 
}

sub CurContext {
	my $self = shift;
	if (@_) { $self->{CURCONTEXT} = shift; }
	return $self->{CURCONTEXT};
}

sub CurContextIsDynamic {
	my $self = shift;
	my $cc = $self->{CURCONTEXT};
	my $d = $self->{CONTEXTDATA}->{$cc};
	if ((exists $d->{dynamic}) and (lc($d->{dynamic}) eq 'true')) {
		return 1
	}
	return ''
}

sub CurRule {
	my $self = shift;
	if (@_) { $self->{CURRULE} = shift; }
	return $self->{CURRULE};
}

sub DebugMode {
	my $self = shift;
	return ($self->{ENGINE}->{MODE} eq 'debug')
}

sub Deliminators {
	my $self = shift;
	if (@_) { $self->{DELIMINATORS} = shift; };
	return $self->{DELIMINATORS};
}

sub Engine {
	my $self = shift;
	return $self->{ENGINE};
}

sub LogWarning {
	my ($self, $warning) = @_;
	if ($self->{ENGINE}->{VERBOSE}) {
		my $msg = 'Syntax: ' . $self->Syntax;
		if ($self->{CURCONTEXT}) {
			$msg = $msg . ', Context: ' . $self->{CURCONTEXT};
			if ($self->{CURRULE} ne '') {
				$msg = $msg . ', Rule: ' . $self->{CURRULE}
			}
		}
		my $call = $self->{ENGINE}->{LOGCALL};
		&$call("$msg, $warning");
	}
}

sub RuleGetArgs {
	my $self = shift;
	my $rule = shift;
	my %booltable = (
		false => 0,
		true => 1,
		yes => 1,
		no  => 0,
		1 => 1,
		0 => 0,
	);
	my %boolopt = (
		dynamic => 0,
		firstNonSpace => 0,
		includeAttrib => 0,
		insensitive => 0,
		lookAhead => 0,
		minimal => 0,
	);
	my %default = (%boolopt,
		context => '#stay',
	);
	my @r = ();
	while (@_) {
		my $n = shift;
		my $d;
		if (exists($rule->{$n})) {
			$d = $rule->{$n};
			if (exists $boolopt{$n}) {
				$d = $booltable{lc($d)};
			}
		} elsif (exists($default{$n})) {
			$d = $default{$n};
		}
		push @r, $d
	}
	return @r
}

sub RuleGetChar {
	my ($self, $char) = @_;
	if (length($char) eq 1) { return $char }
	if ($char =~ /^\\.$/) {
		eval "\$char = \"$char\"";
	}
	return $char
}

my %tests = (
	AnyChar => 'testAnyChar',
	DetectChar => 'testDetectChar',
	Detect2Chars => 'testDetect2Chars',
	DetectIdentifier => 'testDetectIdentifier',
	DetectSpaces => 'testDetectSpaces',
	Float => 'testFloat',
	HlCChar => 'testHlCChar',
	HlCHex => 'testHlCHex',
	HlCOct => 'testHlCOct',
	HlCStringChar => 'testHlCStringChar',
	Int => 'testInt',
	keyword => 'testKeyword',
	LineContinue => 'testLineContinue',
	RangeDetect => 'testRangeDetect',
	RegExpr => 'testRegExpr',
	RegExprS => 'testRegExprSimple',
	StringDetect => 'testStringDetect',
	WordDetect => 'testWordDetect',
);

sub Setup {
	my $self = shift;
	$self->SUPER::Setup;
	
	my $deliminators = ".():!+,-<=>%&*/;?[]^{|}~\\";
	my $wdelim = $self->WeakDeliminator;
	while ($wdelim ne '') {
		$wdelim =~ s/^(.)//;
		my $wd = $1;
		if (index($regchars, $wd) >= 0) { $wd = "\\$wd" };
		$deliminators =~ s/$wd//;
	}
	my $adelim = $self->AdditionalDeliminator;
	$deliminators = $deliminators . $adelim;
	my @delimchars = split //, $deliminators;
	my $delim = '';
	for (@delimchars) {
		my $dc = $_;
		if (index($regchars, $dc ) >= 0) { $dc = "\\$dc" };
		$delim = "$delim|$dc";
	}
	$delim = " |\t|\n|" . $delim;
	$self->{DELIMINATORS} = $delim;
	
	#turn lists into hashes for faster and easier lookup.
	my $lists = $self->Lists;
	for (keys %$lists) {
		my $list = $_;
		my $l = $lists->{$list};
		my %h = ();
		for (@$l) {
			my $elm = $_;
			unless ($self->KeywordsCase) { $elm = lc $elm }
			$h{$elm} = 1;
		}
		$lists->{$list} = \%h;
	}
	
	my %parser = (
		basecontext => $self->BaseContext,
		contexts => {},
		deliminators => $delim,
		lists => $lists,
		syntax => $self->Syntax,
	);
	
	#setup contexts
	my $cond = $self->ContextData;
	for (keys %$cond) {
		$self->CurContext($_);
		$self->SetupContext(\%parser, $_, $cond->{$_})
	}
	$self->CurContext('');
	return \%parser;
}

my %parses = (
	AnyChar => \&SetupRuleAnyChar,
	DetectChar => \&SetupRuleDetectChar,
	Detect2Chars => \&SetupRuleDetect2Chars,
	DetectIdentifier => \&SetupRuleDefault,
	DetectSpaces => \&SetupRuleDefault,
	Float => \&SetupRuleDefault,
	HlCChar => \&SetupRuleDefault,
	HlCHex => \&SetupRuleDefault,
	HlCOct => \&SetupRuleDefault,
	HlCStringChar => \&SetupRuleDefault,
	IncludeRules => \&SetupRuleDefault,
	Int => \&SetupRuleDefault,
	keyword => \&SetupRuleKeyword,
	LineContinue => \&SetupRuleLineContinue,
	RangeDetect => \&SetupRuleRangeDetect,
	RegExpr => \&SetupRuleRegExpr,
	StringDetect => \&SetupRuleStringDetect,
	WordDetect => \&SetupRuleStringDetect,
);

sub SetupContext {
	my ($self, $parser, $ctx, $data) = @_;
	my $eng = $self->{ENGINE};
	my %inf = %$data;
	delete $inf{items};
	my %newcontext = (
		attribute => $eng->FormatTable('Normal'),
		callbacks => [],
		debug => [],
		info => \%inf,
		dynamic => 0,
		emptycontext => sub {},
		endcontext => sub {},
		fallthroughcontext => undef,
	);
	if (exists $data->{'attribute'}) {
		my $attr = $self->AttributeGetF($data->{'attribute'});
		$newcontext{attribute} = $attr;
	}
	if (exists $data->{'lineEmptyContext'}) {
		my $e = $data->{'lineEmptyContext'};
		$e = $self->SetupContextShifter($parser, $e);
		$newcontext{emptycontext} = $e;
	}
	if (exists $data->{'lineEndContext'}) {
		my $e = $data->{'lineEndContext'};
		$e = $self->SetupContextShifter($parser, $e);
		$newcontext{endcontext} = $e;
 	}
	if (exists $data->{'fallthrough'}) {
		my $e = $data->{'fallthrough'};
		if ($e eq 'true') {
			if (exists $data->{'fallthroughContext'}) {
				my $e = $data->{'fallthroughContext'};
				$e = $self->SetupContextShifter($parser, $e);
				$newcontext{fallthroughcontext} = $e;
			}
		}
	}
	if (exists $data->{'dynamic'}) {
		my $e = $data->{'dynamic'};
		if ($e eq 'true') {
			$newcontext{dynamic} = 1;
		}
	}

	my $it = $data->{'items'};
	my ($r, $d) = $self->SetupContextRules($parser, $ctx, @$it);
	$newcontext{callbacks} = $r;
	$newcontext{debug} = $d;
	$parser->{contexts}->{$ctx} = \%newcontext;
}

sub SetupContextRules {
	my $self = shift;
	my $parser = shift;
	my $ctx = shift;
	if (exists $parser->{$ctx}) {
		my $p = $parser->{$ctx};
		return $p->{callbacks}, $p->{debug}
	}
	my @rules = ();
	my @debug = ();
	my $eng = $self->Engine;
	my $num = 0;
	while (@_) {
		my $i = shift;
		$num ++;
		$self->CurRule($num);

# 		#setup debug info
# 		my $path = $self->Syntax . "::$ctx" . "::$num";
# 		$i->{path} = $path;

		my $type = $i->{'type'};
		if ($type eq 'IncludeRules') {
			my $context = $i->{'context'};
			my ($inclattr) = $self->RuleGetArgs($i, qw/ includeAttrib /);
			if ($context =~ s/##(.*)//) { #it refers to another syntax 
				my $language = $1;
				my $p = $eng->{POSTCREATE};
				push @$p, $language;
				if ($language ne $self->Syntax) { #and it refers to another syntax indeed
					if ($inclattr) { # includeAttr is set
						my $attr = $self->AttributeGetF($self->ContextData->{$context}->{'attribute'});
						push @rules, [$eng->can("IncludeLanguageIA"), $language, $context, $attr];
						push @debug, $i;
					} else {
						push @rules, [$eng->can("IncludeLanguage"), $language, $context];
						push @debug, $i;
					}
				} else { #it can be treated as an include rules
					my $data = $self->ContextData->{$context};
					my $items = $data->{'items'};
					$self->CurContext($context);
					if ($inclattr) {
						my ($r, $d) = $self->SetupContextRules($parser, $ctx, @$items);
						push @rules, [$eng->can("IncludeRules"), $r, $d, $inclattr];
						push @debug, $i;
					} else { #if not includeAttr set the rules are literally included.
						my ($r, $d) = $self->SetupContextRules($parser, $ctx, @$items);
						push @rules, $r;
						push @debug, $d;
					}
					$self->CurRule($num);
					$self->CurContext($ctx)
				}
			} else { # it is a normal include rules
				my $data = $self->ContextData->{$context};
				my $items = $data->{'items'};
				my $cback = $self->CurContext;
				$self->CurContext($context);
				if ($inclattr) {
					my ($r, $d) = $self->SetupContextRules($parser, $ctx, @$items);
					my $attr = $self->AttributeGetF($self->ContextData->{$context}->{'attribute'});
					push @rules, [$eng->can("IncludeRules"), $context, $r, $d, $attr];
					push @debug, $i;
				} else { #if not includeAttr set the rules are literally included.
					my ($r, $d) = $self->SetupContextRules($parser, $ctx, @$items);
					push @rules, @$r;
					push @debug, @$d;
				}
				$self->CurRule($num);
				$self->CurContext($cback);
			}
		
		} else {
			#get general options
			my ($lookahead, $column, $firstnonspace, $command, $overstrike, $replace, $beginreg, $endreg) = 
				$self->RuleGetArgs($i, qw/ lookAhead column firstNonSpace command overstrike replace beginRegion endRegion /);

			#get method and rulse specfic options
			my $l = $parses{$type};
			my ($method, @options) = &$l($self, $i);
			if (defined $method) { #returning an undefined method indicates an integrity problem. the rule is skipped.
				$i->{method} = $method;

				#set the method 
				unshift @options, $eng->can($method);

				#add context
				my ($context) = $self->RuleGetArgs($i, qw/ context /);
				$context = $self->SetupContextShifter($parser, $context);
				push @options, $context;
				
				#add attribute
				my ($attribute) = $self->RuleGetArgs($i, qw/ attribute /);
				unless (defined $attribute) { $attribute = '' };
				$attribute = $self->AttributeGetF($attribute);
				push @options, $attribute;
				
				#add beginRegion and endRegion
				push @options, $beginreg, $endreg;

				#prepend column call if needed
				if (defined $column) { 
					unshift @options, $column;
					unshift @options, $eng->can('testCommonColumn');
				}

				#prepend firstNonSpace call if needed
				if ($firstnonspace) { 
					unshift @options, $eng->can('testCommonFirstNonSpace');
				}
				
				#add the command call if needed
				if (defined $command) {
					push @options, $command, $eng->can('ParseResultCommand');
				}
				
				#add the result parser
				my $rparser = 'ParseResult';
				if ($lookahead) { 
					$rparser = $rparser . 'LookAhead' 
				} elsif (defined $overstrike) {
					while (length $overstrike < 128) {
						$overstrike = $overstrike . $overstrike
					}
					push @options, $overstrike;
					$rparser = $rparser . 'OverStrike' ;
					
				} elsif (defined $replace) {
					push @options, $replace;
					$rparser = $rparser . 'Replace' ;
				}
				
				my $p = $eng->can($rparser);
				push @options, $p;
				
				push @rules, \@options;
				push @debug, $i;
				
			}
		}
	}
	$self->CurRule('');
	return \@rules, \@debug
}

sub SetupContextShifter {
	my ($self, $parser, $tcontext) = @_;
	my $eng = $self->Engine;
	if ($tcontext =~ s/##(.*)//) {
		my $syntax = $1;
		unless ($self->SyntaxExists($syntax)) {
			$self->LogWarning("Syntax $syntax does not exist, reverting to #stay");
			return sub {}
		}
		my $p = $eng->{POSTCREATE};
		push @$p, $syntax;
		return sub {
			my $hl = $eng->GetHighlighter($syntax);
			if ($tcontext eq '') { $tcontext = $hl->{basecontext} }
			$eng->StackPush($hl, $tcontext);
		}
	} elsif ($tcontext =~ /^#pop/i) {
		my $count = 0;
		while ($tcontext =~ s/^#pop//i) { $count++ }
		return sub { for (1 .. $count) { $eng->StackPull }}
	} elsif ($tcontext =~ /^#stay/i) {
		return sub {} 
	} else {
		if ($self->ContextExists($tcontext)) {
			my $c = $self->{CONTEXTDATA}->{$tcontext};
			if ((exists $c->{dynamic}) and ($c->{dynamic} eq 'true')){
				return sub { $eng->StackPush($parser, $tcontext) }
			} else {
				return sub { $eng->StackPush($parser, $tcontext) }
			}
		} else {
			$self->LogWarning("Context $tcontext does not exist, reverting to #stay");
			return sub {}
		}
	}
}

sub SetupRuleAnyChar {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, qw/String insensitive/ );
	my $method = $tests{$rule->{'type'}};
	my $string = shift @o;
	my $i = shift @o;
	if ($i) { 
		$method = $method . 'I';
		$string = lc($string)
	}
	return $method, $string
}

sub SetupRuleDefault {
	my ($self, $rule) = @_;
	my $method = $tests{$rule->{'type'}};
	return $method
}

sub SetupRuleDetectChar {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, qw/char insensitive dynamic/ );
	my $method = $tests{$rule->{'type'}};
	my $char = $self->RuleGetChar(shift @o);
	my $i = shift @o;
	my $d = shift @o;
	if ($d and $self->CurContextIsDynamic) {
		$method = $method . 'D';
	}
	if ($i) { 
		$method = $method . 'I';
		$char = lc($char)
	}
	return $method, $char
}

sub SetupRuleDetect2Chars {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, qw/char char1 insensitive dynamic/ );
	my $method = $tests{$rule->{'type'}};
	my $char = $self->RuleGetChar(shift @o);
	my $char1 = $self->RuleGetChar(shift @o);
	my $i = shift @o;
	my $d = shift @o;
	if ($d and $self->CurContextIsDynamic) {
		$method = $method . 'D';
	}
	if ($i) { 
		$method = $method . 'I';
		$char = lc($char);
		$char1 = lc($char1);
	}
	return $method, $char, $char1
}

sub SetupRuleKeyword {
	my ($self, $rule) = @_;
	my ($string) = $self->RuleGetArgs($rule, 'String' );
	my $method = $tests{$rule->{'type'}};
	unless ($self->KeywordsCase) { $method = $method . 'I' }
	my $lsts = $self->{LISTS};
	unless (exists $lsts->{$string}) { 
		$method = undef;
		$self->LogWarning("List $string does not exist");
	}
	my $delim = $self->{DELIMINATORS};
	return $method, $lsts->{$string}, $delim
}

sub SetupRuleLineContinue {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, 'char' );
	my $char = shift @o;
	unless (defined $char) { $char = '\\' }
	$char = $self->RuleGetChar($char);
	if (index($regchars, $char) >= 0) { $char = "\\$char" };
	
	my $method = $tests{$rule->{'type'}};
	return $method, $char 
}

sub SetupRuleRangeDetect {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, qw/char char1 insensitive/ );
	my $method = $tests{$rule->{'type'}};
	my $char = $self->RuleGetChar(shift @o);
	my $char1 = $self->RuleGetChar(shift @o);
	my $i = shift @o;
	if ($i) { 
		$method = $method . 'I';
		$char = lc($char);
		$char1 = lc($char1);
	}
	return $method, $char, $char1
}

sub SetupRuleRegMinimal {
	my ($self, $rule) = @_;
	my ($string, $minimal) = $self->RuleGetArgs($rule, qw/ String minimal /);
# 	my $string = $rule->{'String'};
# 	my $minimal = $rule->{'minimal'};
# 	unless (defined($minimal)) { $minimal = 0 }
# 	$minimal = $self->Booleanize($minimal);
	my $reg = '';
	if ($minimal) {
		my $lastchar = '';
		while ($string ne '') {
			if ($string =~ s/^(\*|\+)//) {
				$reg = "$reg$1";
				if ($lastchar ne "\\") {
					$reg = "$reg?";
				}
				$lastchar = $1;
			} else {
				if ($string =~ s/^(.)//) {
					$reg = "$reg$1";
					$lastchar = $1;
				} 
			}
		}
	} else {
		$reg = $string;
	}
	return $reg
}

sub SetupRuleRegExpr {
	my ($self, $rule) = @_;
	my $reg = $self->SetupRuleRegMinimal($rule);
	my @o = $self->RuleGetArgs($rule, qw/ insensitive dynamic/ );
	my $method = $tests{$rule->{'type'}};
	my $i = shift @o;
	my $d = shift @o;
	my $complex = 0;
	my $prepend;
	if ($reg =~ s/^\^//) { 
		$prepend = 'testCommonLineStart'
	} elsif ($reg =~ s/^\\(b)//i) {
		if ($1 eq 'b') {
			$prepend = 'testCommonLastCharBb'
		} else {
			$prepend = 'testCommonLastCharBB'
		}
	}
	unless ($d and $self->CurContextIsDynamic) { 
		$reg = "^($reg)";
		if ($i) {
			$reg = eval { qr/$reg/i };
		} else {
			$reg = eval { qr/$reg/ };
		}
		if ($@) { #the regex did not compile, the rule is useless
			$self->LogWarning($@);
			return (undef);
		}
	}
	if ($d and $self->CurContextIsDynamic) {
		$method = $method . 'D'
	}
	if ($i) { 
		$method = $method . 'I';
	}
	my @out = ($reg);
	if (defined $prepend) { 
		unshift @out, $prepend, $self->{ENGINE}->can($method) ;
	} else {
		unshift @out, $method
	}
	return @out
}

sub SetupRuleStringDetect {
	my ($self, $rule) = @_;
	my @o = $self->RuleGetArgs($rule, qw/String insensitive dynamic/ );
	my $method = $tests{$rule->{'type'}};
	my $string = shift @o;
	my $i = shift @o;
	my $d = shift @o;
	if ($d and $self->CurContextIsDynamic) {
		$method = $method . 'D'
	}
	if ($i) { 
		$method = $method . 'I';
		$string = lc($string);
	}
	return $method, $string
}

sub SyntaxExists {
	my ($self, $syntax) = @_;
	return (exists $self->Engine->{INDEXER}->{INDEX}->{$syntax})
}

# sub XMLGetLanguage {
# 	my ($self, $token, $parser) = @_;
# 	my $args = $token->[2];
# 	$self->Language($args->{'name'});
# }


1;

__END__

