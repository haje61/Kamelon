use strict;
use warnings;

use Test::More tests => 1;
my $skip = 1;

use Syntax::Kamelon;

my $reffile = './t/HTML/codefolding.txt';
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
# 		foldbegincall => \&FoldBegin,
# 		foldendcall => \&FoldEnd,
		substitutions => $substitutions,
		format_table => \%formtab,
	],
	syntax => 'Perl',
);

my $output = "";


my $outfile = "$outdir/codefolding.txt";
unless (open(OFILE, ">", $outfile)) {
	die "Cannot open output $outfile"
}
unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}
while (my $in = <IFILE>) {
	$hl->Parse($in);
}


my $foldingpoints = $hl->Formatter->{FOLDHASH};

for (sort keys %$foldingpoints) {
	my $p = $foldingpoints->{$_};
	my @o = @$p;
	&Out("$_ => ");
	for (@o) {
		&Out($_ . ", ");
	}
	&Out("\n");
}

close IFILE;
close OFILE;

my $reftext = &LoadFile($reffile);
ok(($reftext eq $output), 'Codefolding');

# sub FoldBegin {
# 	my $region = shift;
# 	$hl->SnippetParse("<$region>", $doctag);
# }
# 
# sub FoldEnd {
# 	my $region = shift;
# 	$hl->SnippetParse("</$region>", $doctag);
# }

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

