package KamTest;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(InitWorkFolder LoadFile Out PreText PostText TestParse);


our $workfolder;
our $outfolder;
our $reffolder;
our $samplefolder;
our $pretext = "";
our $posttext = "";
our $output = "";

sub InitWorkFolder {
	$workfolder = shift;
	unless (-e $workfolder) {
		die "workfolder $workfolder does not exist"
	}
	$outfolder = "$workfolder/output";
	unless (-e $outfolder) {
		mkdir $outfolder
	}
	$reffolder = "$workfolder/reference_files";
	unless (-e $reffolder) {
		die "reference folder $reffolder does not exist"
	}
	$samplefolder = "$workfolder/samples";
	unless (-e $reffolder) {
		die "sample folder $samplefolder does not exist"
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

sub Out {
	my $out = shift;
	$output = $output . $out;
	print OFILE $out;
}

sub PreText {
	$pretext = shift;
}

sub PostText {
	$posttext = shift;
}

sub TestParse {
	my ($kam, $samplefile, $outfile) = @_;
	$output = "";

	unless (open(OFILE, ">", "$outfolder/$outfile")) {
		die "Cannot open output $outfile"
	}

	unless (open(IFILE, "<", "$samplefolder/$samplefile")) {
		die "Cannot open input $samplefile"
	}

	Out($pretext);
	while (my $in = <IFILE>) {
		$kam->Parse($in);
	}

	my $out = $kam->Format;
	Out($out);
	Out($posttext);

	close OFILE;
	close IFILE;

	my $refdata = LoadFile("$reffolder/$outfile");

	if ($refdata eq $output) {
		return 1
	}
	return 0
}

1;
