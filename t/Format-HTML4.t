use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Syntax::Kamelon::Format::HTML4') };

use Syntax::Kamelon;

my $reffile = './t/HTML/format-html4';
my $samplefile = './t/Samples/codefolding.pm';
my $outfile = './t/HTML_OUT/format-html4';

my $kam1 = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['HTML4',
	],
);

my @tests = ($kam1);
my $testnum = 1;
for (@tests) {
	my $kam = $_;
	my $output = "";

	ok(defined $kam->Formatter, "Creation test $testnum");

	my $ofile = "$outfile-$testnum.html";
	unless (open(OFILE, ">", $ofile)) {
		die "Cannot open output $ofile"
	}

	unless (open(IFILE, "<", $samplefile)) {
		die "Cannot open input $samplefile"
	}

	while (my $in = <IFILE>) {
		$kam->Parse($in);
	}

	my $out = $kam->Format;
	$output = $output . $out;
	print OFILE $out;

	close IFILE;
	close OFILE;

	my $rfile = "$reffile-$testnum.html";
# 	my $reftext = &LoadFile($rfile);
# 	ok($reftext eq $output, "Parse test $testnum");
	$testnum ++;
}

sub LoadFile {
	my $file = shift;
	my $text = '';
	unless (open(AFILE, "<", $file)) {
		die "Cannot open $file"
	}
	while (my $in = <AFILE>) {
		$text = $text . $in
	}
	close AFILE;
	return $text;
}
