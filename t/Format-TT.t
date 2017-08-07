use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Syntax::Kamelon::Format::TT') };

use Syntax::Kamelon;

my $reffile = './t/HTML/format-tt.html';
my $samplefile = './t/Samples/codefolding.pm';
my $outfile = './t/HTML_OUT/format-tt.html';
my $template = 't/Samples/template.tpl';

unless (-e $template) { die "template does not exist" }

my $kam = Syntax::Kamelon->new(
	syntax => 'Perl',
	formatter => ['TT',
		template => $template,
	],
);

my $output = "";

ok(defined $kam->Formatter, 'Creation');

unless (open(OFILE, ">", $outfile)) {
	die "Cannot open output $outfile"
}
unless (open(IFILE, "<", $samplefile)) {
	die "Cannot open input $samplefile"
}

while (my $in = <IFILE>) {
	$kam->Parse($in);
}

&Out($kam->Format);

close IFILE;
close OFILE;

my $reftext = &LoadFile($reffile);
ok($reftext eq $output, 'TT Template Toolkit');

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

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}


