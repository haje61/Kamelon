package Syntax::Kamelon::Format::HTML4;

use strict;
use warnings;
use Carp;
use List::Util 'any';

use vars qw($VERSION);
$VERSION="0.01";

use base qw(Syntax::Kamelon::Format::Base);

my $default_header = <<__EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
[% IF inlinecss == 1 ~%]
	<style>
   [%- stylesheet ~%]
   </style>
[% ELSE ~%]
   <link rel="stylesheet" href="[% stylesheet %]" type="text/css">
[% END ~%]
<title>[% title %]</title>
</head>
<body>
__EOF

my $default_footer = <<__EOF;
</body>
</html>
__EOF

my $default_template = <<__EOF;
[% header %]
[% userdefined %]
[% panel.begin %]
[% IF lineoffset.defined ~%]
	[% linenum = lineoffset ~%]
[% ELSE ~%]
	[% linenum = 1 ~%]
[% END ~%]
[% FOREACH line = content ~%]
	[% IF lineoffset.defined ~%]
		[% linenum  FILTER format('\%04d') ~%]&nbsp;
		[% linenum = linenum + 1 ~%]
	[% END %]
	[%~ FOREACH snippet = line ~%]
		<font class="[% snippet.tag %]">
			[%~ snippet.text FILTER html FILTER replace('\\040', '&nbsp;') FILTER replace('\\t', '&nbsp;&nbsp;&nbsp;') ~%]
		</font>
	[%~ END %][% newline ~%]
[% END ~%]
[% panel.end %]
[% footer %]
__EOF

my $style_plain_begin = <<__EOF;
<div id="content">
__EOF

my $style_plain_end = <<__EOF;
</div>
__EOF

my $style_scrolled_begin = <<__EOF;
__EOF

my $style_scrolled_end = <<__EOF;
__EOF


sub new {
   my $class = shift;
   my $engine = shift;
	my %args = (@_);

	#We overwrite the following options for parent Base unless the user already set an option
	unless (exists $args{newline}) { $args{newline} = "<br>\n" }
	unless (exists $args{template}) { $args{template} = \$default_template }
	unless (exists $args{tagend}) { $args{tagend} = </font> }

	#We retrieve our own options
	my $footer = delete $args{footer};
	unless (defined $footer) { $footer = \$default_footer }

	my $header = delete $args{header};
	unless (defined $header) { $header = \$default_header }

	my $inlinecss = delete $args{inlinecss};
	unless (defined $inlinecss) { $inlinecss = 1 }

	my $styles = delete $args{styles};
	unless (defined $styles) { $styles = [qw/ plain /] }
	#We deal with the stylesheet later on
	my $stylesheet = delete $args{stylesheet};

	my $themefolder = delete $args{themefolder};
	unless (defined $themefolder) {
		$themefolder = $engine->GetIndexer->FindINC('Syntax/Kamelon/Format/HTML4', 1)
	}
	unless (defined $themefolder) {
		die "theme folder not found"
	}
	unless (-e $themefolder) {
		die "theme folder does not exist"
	}
	unless (-d $themefolder) {
		die "theme folder is not a folder"
	}

	my $theme = delete $args{theme};
	unless (defined $theme) { $theme = 'DarkGray' }

	unless (defined $stylesheet) {
		$stylesheet = "$themefolder/$theme.css";
	}
	unless (-e $stylesheet) { die "stylesheet not found" }

	my $title = delete $args{title};
	unless (defined $title) { $title = 'Kamelon output' }

	my $self = $class->SUPER::new($engine, %args);

	$self->{FOOTER} = $footer;
	$self->{HEADER} = $header;
	$self->{INLINECSS} = $inlinecss;
	$self->{STYLESHEET} = $stylesheet;
	$self->{STYLES} = $styles;
	$self->{TITLE} = $title;
	$self->{THEMEFOLDER} = $themefolder;
	return $self;
}

sub Format {
	my $self = shift;

	#processing the header
	my $stylesheet;
	if ($self->{INLINECSS}) {
		$stylesheet = $self->LoadFile($self->{STYLESHEET});
	} else {
		$stylesheet = $self->{STYLESHEET}
	}
	my $d = $self->{DATA};
	my %data = (%$d,
		inlinecss => $self->{INLINECSS},
		stylesheet => $stylesheet,
		title => $self->{TITLE},
	);
	$self->{HEADERTEXT} = $self->Process($self->{HEADER}, \%data,);

	#process the footer
	$self->{FOOTERTEXT} = $self->Process($self->{FOOTER}, $self->{DATA});

	#processing the style elements
	my $s = $self->{STYLES};
	my @styles = @$s;
	my $panel_begin = '';
	my $panel_end = '';
	if (any { /scrolled/ } @styles) {
		$panel_begin = $self->Process(\$style_scrolled_begin, $self->{DATA});
		$panel_end = $self->Process(\$style_scrolled_end, $self->{DATA});
	} else {
		$panel_begin = $self->Process(\$style_plain_begin, $self->{DATA});
		$panel_end = $self->Process(\$style_plain_end, $self->{DATA});
	}
	$self->{PANELTEXT} = {
		begin => $panel_begin,
		end => $panel_end,
	};

	#format the whole bunch with the parsed text
	return $self->SUPER::Format;
}

sub GetData {
	my $self = shift;
	my $data = $self->SUPER::GetData;
	$data->{header} = $self->{HEADERTEXT};
	$data->{footer} = $self->{FOOTERTEXT};
	$data->{panel} = $self->{PANELTEXT};
	return $data
}

sub LoadFile {
	my ($self, $file) = @_;
	open IN, "<$file" or return undef;
	my $out = '';
	while (my $line = <IN>) {
		$out = $out . $line;
	}
	close IN;
	return $out
}

1;
__END__
