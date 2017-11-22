package KamTest;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(InitOutFolder LoadFile TestParse);


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
	my ($kam, $reffile, $outfile, $samplefile) = @_;
	my $output = "";

	unless (open(OFILE, ">", "$outfolder/$outfile")) {
		die "Cannot open output $outfile"
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
	
	close OFILE;
	close IFILE;
	
	my $refdata = LoadFile($reffile);

}

1;
