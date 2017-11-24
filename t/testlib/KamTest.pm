package KamTest;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	CompareFile
	InitWorkFolder
	LoadFile
	Format
	OutPut
	Parse
	PreText
	PostText
	TestParse
);


our $workfolder;
our $outfolder;
our $reffolder;
our $samplefolder;
our $pretext = "";
our $posttext = "";
our $output = "";

sub CompareFile {
	my $file = shift;
	my $refdata = LoadFile("$reffolder/$file");
	if ($refdata eq $output) {
		return 1
	}
	return 0
}

sub Format {
	$output = "";
	my ($kam, $file) = @_;
	unless (open(OFILE, ">", "$outfolder/$file")) {
		die "Cannot open output $file"
	}
	Out($pretext);
	Out($kam->Format);
	Out($posttext);
	close OFILE;
	return $output;
}

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
		warn "Cannot open $file";
		return ''
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

sub OutPut {
	my ($out, $file) = @_;
	$output = $pretext . $out . $posttext;
	unless (open(OFILE, ">", "$outfolder/$file")) {
		die "Cannot open output $file"
	}
	print OFILE $output;
	close OFILE;
}

sub Parse {
	my ($kam, $samplefile) = @_;
	unless (open(IFILE, "<", "$samplefolder/$samplefile")) {
		die "Cannot open input $samplefile"
	}
	while (my $in = <IFILE>) {
		$kam->Parse($in);
	}
	close IFILE;
}

sub PreText {
	$pretext = shift;
}

sub PostText {
	$posttext = shift;
}

sub TestParse {
	my ($kam, $samplefile, $outfile) = @_;
	Parse($kam, $samplefile);
	Format($kam, $outfile);
	return CompareFile($outfile);
}

1;
