use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 18;

use Syntax::Kamelon;

my $htmldir = './t/HTML';
my $sampledir = './t/Samples';
my $outdir = './t/HTML_OUT';
my $xmldir = './t/XML';
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
	xmlfolder => $xmldir,
	noindex => 1,
	formatter => ['Base',
		substitutions => $substitutions,
		format_table => \%formtab,
	],
);
ok(defined $hl, 'Creation');

my $sb = $hl->{FORMATTER}->{SUBSTITUTIONS};

ok((Dumper $substitutions eq Dumper $sb), "Substitutions");

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
	my $outfile = "$outdir/$_.html";
	$hl->Syntax($_);
	unless (open(OFILE, ">", $outfile)) {
		die "Cannot open output $outfile"
	}
	unless (open(IFILE, "<", $infile)) {
		die "Cannot open input $infile"
	}
	&Out("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
	&Out("<html>\n<head>\n");
	&Out("<link rel=\"stylesheet\" href=\"defaultstyle.css\" type=\"text/css\">\n");
	&Out("<title>Testfile $_</title>\n");
	&Out("</head>\n<body>\n");
	while (my $in = <IFILE>) {
		$hl->Parse($in);
	}
	&Out($hl->Get);
	&Out("</body>\n</html>\n");
	close IFILE;
	close OFILE;
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
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

