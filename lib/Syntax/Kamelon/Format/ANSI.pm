package Syntax::Kamelon::Format::ANSI;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use base qw(Syntax::Kamelon::Format::TT);
use Term::ANSIColor;

my %styles = (

	black => {
		Alert => color('white bold on_green'),
		Annotation => color('black on_yellow'),
		Attribute => color('yellow bold'),
		BaseN => color('green'),
		BuiltIn => color('yellow bold'),
		Char => color('magenta'),
		Comment => color('white bold on_bright_black'),
		CommentVar => color('green bold'),
		Constant => color('magenta bold'),
		ControlFlow => color('blue bold on_yellow'),
		DataType => color('bright_blue'),
		DecVal => color('bright_blue bold'),
		Documentation => color('black on_white'),
		Error => color('yellow bold on_red'),
		Extension => color('magenta on_blue'),
		Float => color('bright_blue bold'),
		Function => color('yellow bold on_blue'),
		Import => color('red on_white'),
		Information => color('blue on_white'),
		Keyword => color('white bold'),
		Normal => color('white'),
		Operator => color('green'),
		Others => color('yellow bold on_green'),
		Preprocessor => color('blue on_yellow'),
		RegionMarker => color('black on_yellow'),
		SpecialChar => color('red on_green'),
		SpecialString => color('red on_bright_yellow'),
		String => color('red'),
		Variable => color('blue bold on_red'),
		VerbatimString  => color('red on_blue'),
		Warning => color('green bold on_red'),
	},

	blue => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},

	cyan => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},

	green => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},

	magenta => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},

	white => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},

	yellow => {
		Alert => '',
		Annotation => '',
		Attribute => '',
		BaseN => '',
		BuiltIn => '',
		Char => '',
		Comment => '',
		CommentVar => '',
		Constant => '',
		ControlFlow => '',
		DataType => '',
		DecVal => '',
		Documentation => '',
		Error => '',
		Extension => '',
		Float => '',
		Function => '',
		Import => '',
		Information => '',
		Keyword => '',
		Normal => '',
		Operator => '',
		Others => '',
		Preprocessor => '',
		RegionMarker => '',
		SpecialChar => '',
		SpecialString => '',
		String => '',
		Variable => '',
		VerbatimString  => '',
		Warning => '',
	},
);

my $template_numbered = <<__EOF;
[% linenum = lineoffset ~%]
[% FOREACH line = content ~%]
	[% linenum = linenum + 1 ~%]
	[% linenum  FILTER format('%03d ') ~%]
	[%~ FOREACH snippet = line ~%]
		[%~ snippet.tag %][% snippet.text %][% colorreset ~%]
	[%~ END %]
[% END ~%]
__EOF

my $template_plain = <<__EOF;
[% FOREACH line = content ~%]
	[%~ FOREACH snippet = line ~%]
		[%~ snippet.tag %][% snippet.text %][% colorreset ~%]
	[%~ END %]
[% END ~%]
__EOF

sub new {
   my $class = shift;
   my $engine = shift;
	my %args = (@_);

	my $style = delete $args{style};
	unless (defined $style) { $style = 'black' }
	unless (exists $args{format_table}) {
		if (exists $styles{$style} ) {
			$args{format_table} = $styles{$style};
		} else {
			die "Invalid style: $style"
		}
	}
	my $offset = delete $args{lineoffset};
	my $template = $template_plain;
	if (defined $offset) {
		$template = $template_numbered;
	}
	$args{template} = \$template;

	my $self = $class->SUPER::new($engine, %args);

	if (defined $offset) {
		$self->{LINEOFFSET} = $offset;
	}
	return $self;
}

sub GetData {
	my $self = shift;
	my $data = $self->SUPER::GetData;
	$data->{colorreset} = color('reset');
	if (defined $self->{LINEOFFSET}) {
		$data->{lineoffset} = $self->{LINEOFFSET} - 1;
	}
	return $data
}

1;
__END__
