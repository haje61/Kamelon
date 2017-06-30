use strict;
use warnings;

use Test::More tests => 1;
my $skip = 1;

use Syntax::Kamelon;

my $reffile = './t/HTML/codefolding.html';
my $samplefile = './t/Samples/codefolding.pm';
my $outdir = './t/HTML_OUT';
my @attributes = Syntax::Kamelon->AvailableAttributes;

my %formtab = ();
for (@attributes) {
	$formtab{$_} = ["<font class=\"$_\">", "</font>"]
}

my $substitutions = {
	'<' => '&lt;',
	'>' => '&gt;',
	'&' => '&amp;',
	' ' => '&nbsp;',
	"\t" => '&nbsp;&nbsp;&nbsp;',
	"\n" => "<BR>\n",
};


my $hl = new Syntax::Kamelon(
	noindex => 1,
	formatter => ['Base',
		folding => 1,
		foldbeginpostcall => \&FoldBeginPost,
		foldbeginprecall => \&FoldBeginPre,
		foldendpostcall => \&FoldEndPost,
		foldendprecall => \&FoldEndPre,
		substitutions => $substitutions,
		format_table => \%formtab,
	],
	syntax => 'Perl',
);

my $output = "";
my $doctag = $hl->Formatter->FormatTable("Documentation");
print $doctag->[0], "\n";;
print $doctag->[1], "\n";;


my $outfile = "$outdir/codefolding.html";
unless (open(OFILE, ">", $outfile)) {
	die "Cannot open output $outfile"
}
unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}
&Out("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
&Out("<html>\n<head>\n");
&Out("<link rel=\"stylesheet\" href=\"defaultstyle.css\" type=\"text/css\">\n");
&Out("<title>Testfile Codefolding</title>\n");
&Out("</head>\n<body>\n");
while (my $in = <IFILE>) {
	$hl->Parse($in);
}
&Out($hl->Get);
&Out("</body>\n</html>\n");
close IFILE;
close OFILE;

my $reftext = &LoadFile($reffile);
ok(($reftext eq $output), 'Codefolding');

sub FoldBeginPost {
	my $region = shift;
	$hl->SnippetParse("<POST$region>", $doctag);
}

sub FoldBeginPre {
	my $region = shift;
	$hl->SnippetParse("<PRE$region>", $doctag);
}

sub FoldEndPost {
	my $region = shift;
	$hl->SnippetParse("</POST$region>", $doctag);
}

sub FoldEndPre {
	my $region = shift;
	$hl->SnippetParse("</PRE$region>", $doctag);
}

sub FoldEnd {
	my $region = shift;
	$hl->PushOut("</PRE$region>", $doctag);
}

sub LoadFile {
	my $file = shift;
	my $text = '';
	unless (open(IFILE, "<", $file)) {
		die "Cannot open $file"
	}
	while (my $in = <IFILE>) {
		$text = $text . $in
	}
	close IFILE;
	return $text;
}

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

