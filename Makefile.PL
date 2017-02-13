use strict;

my $pmfile = 'Kamelon/lib/Syntax/Kamelon.pm';

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Syntax::Kamelon',
    VERSION_FROM      => $pmfile, # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
		'XML::TokeParser' => 0,
		'Time::HiRes' => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => $pmfile, # retrieve abstract from module
);
 
