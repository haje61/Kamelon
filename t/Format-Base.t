use strict;
use warnings;

use Test::More tests => 4;
BEGIN { use_ok('Syntax::Kamelon::Format::Base') };

use Syntax::Kamelon;

my $substitutions = {
	'<' => '&lt;',
	'>' => '&gt;',
	'&' => '&amp;',
	' ' => '&nbsp;',
	"\t" => '&nbsp;&nbsp;&nbsp;',
	"\n" => "<BR>\n",
};

my $formattable = {
	Normal => 'Normal'
};

my $base = Syntax::Kamelon::Format::Base->new(1,
	substitutions => $substitutions,
	format_table => $formattable,
);

ok(defined $base, 'Creation');

ok(($base->{ENGINE} eq 1), 'Engine');

ok(($base->{SUBSTITUTIONS} eq $substitutions), 'Substitutions');

my $folder = './t';

my $kam = Syntax::Kamelon->new(
	noindex => 1,
	xmlfolder => $folder,
);
$kam->Syntax("Test");

