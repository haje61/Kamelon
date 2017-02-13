use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 22;
BEGIN { use_ok('Syntax::Kamelon::Debugger') };

use Syntax::Kamelon;
my $folder = './t';
my $index = "$folder/indexrc";
unlink $index;

my $hl = Syntax::Kamelon::Debugger->new(
	xmlfolder => $folder,
	indexfile => $index,
	mode => 'debug',
);

ok(defined $hl, 'Can create Kamelon debugger');



ok($hl->{INDEXER}->{INDEX}->{'Test'}->{'file'} eq 'test.xml', "Indexing\n");

$hl->Reset;

$hl->Syntax('Test');
ok($hl->Syntax eq 'Test', 'Set a language');

my $thl = $hl->GetHighlighter('Test');
ok(defined $thl, 'Create a highlighter');

$hl->Reset;
my @expected = ('highlight', 'Normal');
my @result = $hl->Highlight("highlight");
# for (@result) { print "$_ " } print "\n";
ok(&ListCompare(\@expected, \@result), 'unmatched text');

unlink $index;

my $htmldir = './t/HTML';
my $sampledir = './t/Samples';
my $xmldir = './t/XML';
my @attributes = Syntax::Kamelon->AvailableAttributes;

my %formtab = ();
for (@attributes) {
	$formtab{$_} = ["<font class=\"$_\">", "</font>"]
}

$hl = new Syntax::Kamelon(
	xmlfolder => $xmldir,
	mode => 'debug',
	noindex => 1,
	substitutions => {
		'<' => '&lt;',
		'>' => '&gt;',
		'&' => '&amp;',
		' ' => '&nbsp;',
		"\t" => '&nbsp;&nbsp;&nbsp;',
		"\n" => "<BR>\n",
	},
	format_table => \%formtab,
);

my @l = $hl->AvailableSyntaxes;
my @li = ();
for (@l) {
	if ($hl->{INDEXER}->InfoSection($_) eq 'Test') {
		push @li, $_
	}
}

my $output = "";

for (@li) {
	$output = "";
	my $infile = "$sampledir/highlight.$_";
	my $reffile = "$htmldir/$_.html";
	$hl->Syntax($_);
	unless (open(IFILE, "<", $infile)) {
		die "Cannot open $infile"
	}
	&Out("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
	&Out("<html>\n<head>\n");
	&Out("<link rel=\"stylesheet\" href=\"defaultstyle.css\" type=\"text/css\">\n");
	&Out("<title>Testfile $_</title>\n");
	&Out("</head>\n<body>\n");
	while (my $in = <IFILE>) {
		&Out( $hl->HighlightAndFormat($in));
	}
	&Out("</body>\n</html>\n");
	close IFILE;
	my $reftext = &LoadFile($reffile);
	ok(($reftext eq $output), $_);
}


sub ListCompare {
	my ($l1, $l2) = (@_);
	if (Dumper $l1 eq Dumper $l2) { return 1 }
	return 0
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
	$output = $output . shift;
}

