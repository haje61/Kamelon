package Syntax::Kamelon::Indexer;

use strict;
use warnings;

my $VERSION = '0.01';


sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
	my %args = (@_);

	my $indexfile = delete $args{'indexfile'};
	my $noindex = delete $args{'noindex'};
	my $xmlfolder = delete $args{'xmlfolder'};

	my $self = {};
   bless ($self, $class);

   unless (defined($xmlfolder)) { $xmlfolder = $self->FindINC('Syntax/Kamelon/XML') };
	unless (defined($indexfile)) { $indexfile = "$xmlfolder/indexrc" };
	unless (defined($noindex)) { $noindex = 0 };
	$self->{EXTENSIONS} = '';
	$self->{INDEX} = {};
	$self->{INDEXFILE} = $indexfile;
	$self->{XMLFOLDER} = $xmlfolder;
	
	
	$self->LoadIndex($noindex);

   return $self;
}

sub AvailableSyntaxes {
	my $self = shift;
	my $i = $self->{INDEX};
	return sort keys %$i
}

sub CreateIndex {
	my $self = shift;
	my $folder = $self->XMLFolder;
	if (opendir DIR, $folder) {
		my %index = ();
		while (my $file = readdir(DIR)) {
			if ($file =~ /.*\.xml$/) {
				my $xml = $self->LoadXML(xmlfile => "$folder/$file");
				if (defined $xml) {
					my $l = $xml->Language;
					$index{$l->{'name'}} = { 
						file => $file,
						ext =>  $l->{'extensions'},
						menu => $l->{'section'},
						mime => $l->{'mimetype'},
					};
				}
			} else {
			}
		}
		closedir DIR;
		$self->{INDEX} = \%index;
	}
}

sub CreateExtIndex {
	my $self = shift;
	my $index = $self->{INDEX};
	my %eindex = ();
	for (keys %$index) {
		my $lang = $_;
		my @o = $index->{$lang}->{'ext'};
		for (@o) {
			my $e = $_;
			if (exists $eindex{$e}) {
				my $p = $eindex{$e};
				push @$p, $lang;
			} else {
				$eindex{$e} = [ $lang ];
			}
		}
	}
	if (%eindex) {
		$self->{EXTENSIONS} = \%eindex;
	}
}

sub ExtensionLanguages {
	my ($self, $item) = @_;
	my $l = $self->{EXTENSIONS};
	unless (defined $item ){ return }
	if (my $s = $self->{EXTENSIONS}->{$item}) {
		return @$s
	}
}

sub Extensions {
	my $self = shift;
	if (@_) { $self->{EXTENSIONS} = shift; }
	if ($self->{EXTENSIONS} eq '') {
		$self->CreateExtIndex;
	}
	return $self->{EXTENSIONS};
}

sub FindINC {
   my ($self, $file) = @_;
   for (@INC) {
      my $f = $_ . "/$file";
      if (-e $f) {
         return $f;
      }
   }
   return undef;
}

sub GetXMLObject {
	my ($self, $syntax) = @_;
	my $p = $self->{XMLPOOL};
	my $id = $self->{INDEXER};
	my $i = $id->{INDEX};
	if (exists $p->{$syntax}) {
		return $p->{$syntax}
	} elsif (exists $i->{$syntax}) {
		my $file = $id->{XMLFOLDER} . '/' . $i->{$syntax}->{'file'};
		my $hl = Syntax::Kamelon::XMLData->new(
			xmlfile => $file,
		);
 		$self->{XMLPOOL}->{$syntax} = $hl;
		return $hl
	} else {
		warn "XML file for $syntax is not indexed. Please load manually\n";
	}
}

sub IndexFile {
	my $self = shift;
	if (@_) { $self->{INDEXFILE} = shift; }
	return $self->{INDEXFILE};
}

sub Info {
	my ($self, $syntax, $tag) = @_;
	my $i = $self->{INDEX};
	my $l = $i->{$syntax};
	if (defined $l) {
		my $t = $l->{$tag};
		if (defined $t) {
			return $t
		}
	}
}

sub InfoExtensions {
	my ($self, $syntax) = @_;
	my $e = $self->Info($syntax, 'ext');
	
	return $e
}

sub InfoMimeType {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'mime')
}

sub InfoSection {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'menu')
}

sub InfoXMLFile {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'file')
}

sub LoadIndex {
	my ($self, $noindex) = @_;
	my $file = '';
	unless ($noindex) { $file = $self->IndexFile }
	if (-e $file) {
		if (open(OFILE, "<", $file)) {
			my %index = ();
			my $section;
			my %inf = ();
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ /^\[([^\]]+)\]/) { #new section
					if (defined $section) { $index{$section} = { %inf } }
					$section = $1;
					%inf = ();
				} elsif ($line =~ s/^([^=]+)=//) {#new key
					$inf{$1} = $line;
				}
			}
			$index{$section} = { %inf };
			close OFILE;
			$self->{INDEX} = \%index;
		}
	} else {
		$self->CreateIndex;
		unless ($noindex) { $self->SaveIndex }
	}
}

sub LoadXML {
	my $self = shift;
	return Syntax::Kamelon::XMLData->new(@_)
}

sub SaveIndex {
	my $self = shift;
	my $file = $self->IndexFile;
	my $i = $self->{INDEX};
	if (open(OFILE, ">", $file)) {
		for (sort keys %$i) {
			print OFILE "[", $_, "]", "\n";
			my $k = $i->{$_};
			for (sort keys %$k) {
				my $v = $k->{$_};
				unless (defined $v) { $v ='' }
				print OFILE $_, '=', $v, "\n";
			}
			print OFILE "\n";
		}
		close OFILE;
		return 1
	}
}

sub SyntaxList {
	my $self = shift;
	my $i = $self->{INDEX};
	return sort keys %$i
}

sub XMLFolder {
	my $self = shift;
	if (@_) { $self->{XMLFOLDER} = shift; }
	return $self->{XMLFOLDER};
}


1;