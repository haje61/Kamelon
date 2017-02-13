#!/usr/bin/perl -w

use strict;
my $htmldir = './testhtml';
my $sampledir = './t/Samples';
my $xmldir = './t/XML';

use Syntax::Kamelon;


my @attributes = Syntax::Kamelon->AvailableAttributes;

my %formtab = ();
for (@attributes) {
	$formtab{$_} = ["<font class=\"$_\">", "</font>"]
}

my $hl = new Syntax::Kamelon(
	xmlfolder => $xmldir,
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

my @l = $hl->{INDEXER}->SyntaxList;
my @li = ();
for (@l) {
	if ($hl->{INDEXER}->InfoSection($_) eq 'Test') {
		push @li, $_
	}
}

for (@li) {
	my $infile = "$sampledir/highlight.$_";
	my $outfile = "$htmldir/$_.html";
	$hl->Syntax($_);
	unless (open(IFILE, "<", $infile)) {
		die "Cannot open $infile"
	}
	unless (open(OFILE, ">", $outfile)) {
		die "Cannot open $outfile"
	}
	print OFILE "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
	print OFILE "<html>\n<head>\n";
	print OFILE "<link rel=\"stylesheet\" href=\"defaultstyle.css\" type=\"text/css\">\n";
	print OFILE "<title>Testfile $_</title>\n";
	print OFILE "</head>\n<body>\n";
	while (my $in = <IFILE>) {
		print OFILE $hl->HighlightAndFormat($in);
	}
	print OFILE "</body>\n</html>\n";
	close IFILE;
	close OFILE;
}

my $index = "$htmldir/index.html";
unless (open(OFILE, ">", $index)) {
	die "Cannot open $index"
}

print OFILE "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n";
print OFILE "<html>\n<head>\n";
print OFILE "<link rel=\"stylesheet\" href=\"defaultstyle.css\" type=\"text/css\">\n";
print OFILE "<title>Testfiles Syntax::Highlight::Engine::Kate</title>\n";
print OFILE "</head>\n<body>\n";
for (@li) {
	print OFILE "<p><a href=\"$_.html\">$_</a></p>\n"; 
}
print OFILE "</body>\n</html>\n";
close OFILE;
