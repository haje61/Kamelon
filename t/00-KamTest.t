package KamelonEmulator;

use strict;
use warnings;

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
	my $self = {
		DATA => ''
	};
   bless ($self, $class);
}

sub Format {
	my $self = shift;
	return $self->{DATA};
}

sub Parse {
	my $self = shift;
	$self->{DATA} = $self->{DATA} . shift;
}


package main;

use strict;
use warnings;
use lib 't/testlib';


use Test::More tests => 3;

BEGIN { use_ok('KamTest') };

my $tmpfolder = 't/outtest';
unlink $tmpfolder;
InitOutFolder($tmpfolder);
ok(-e $tmpfolder, "Setting output folder");
unlink $tmpfolder;

my $kam = new KamelonEmulator;

my $outfolder = 't/KamTest';
InitOutFolder($outfolder);

my $reffile = 't/KamTest/samplefile.txt';
my $outfile = 'output.txt';
ok(TestParse($kam, $reffile, $outfile, $reffile), 'Parsing');

