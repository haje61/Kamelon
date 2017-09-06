package Syntax::Kamelon::Format::HTML4;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use base qw(Syntax::Kamelon::Format::Base);

sub new {
   my $class = shift;
   my $engine = shift;
	my %args = (@_);

	my $self = $class->SUPER::new($engine, %args);
	return $self;
}

1;
__END__
