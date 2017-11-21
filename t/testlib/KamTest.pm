package KamTest;

use strict;
use warnings;

our $outfolder;

sub InitOutFolder {
	$outfolder = shift;
	unless (-e $outfolder) {
		mkdir $outfolder
	}
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

sub TestParse {
	my ($kam, $reffile) = @_;
	my $output = "";

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

}

1;
