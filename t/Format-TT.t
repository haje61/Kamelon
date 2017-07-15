use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Syntax::Kamelon::Format::TT') };

use Syntax::Kamelon;

my $kam = Syntax::Kamelon->new(
	noindex => 1,
	formatter => ['TT',
	],
);

ok(defined $kam->Formatter, 'Creation');



