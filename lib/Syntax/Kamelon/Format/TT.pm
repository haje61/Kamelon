package Syntax::Kamelon::Format::TT;

use strict;
use warnings;
use Carp;

use vars qw($VERSION);
$VERSION="0.01";

use base qw(Syntax::Kamelon::Format::Base);
use Template;


sub new {
   my $class = shift;
   my $engine = shift;
   my %args = (@_);
	
	my $fold = delete $args{foldmarkers};
	my $index = delete $args{'index'};
	my $style = delete $args{style};
	my $substitutions = delete $args{substitutions};
	my $wrap = delete $args{wrap};

	my $self = $class->SUPER::new($engine, %args);
	
	unless (defined $fold) { $fold = 0 }
	unless (defined $index) { $index = 0 }

	return $self;
}

sub FoldBegin {
	my ($self, $region) = @_;
}

sub FoldEnd {
	my ($self, $region) = @_;
}

sub FoldEndCall {
	my $self = shift;
}

1;
__END__
