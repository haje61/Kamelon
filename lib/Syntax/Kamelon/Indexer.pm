package Syntax::Kamelon::Indexer;

use 5.006;
use strict;
use warnings;
use Syntax::Kamelon::XMLData;

my $VERSION = '0.23';


sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
	my %args = (@_);

	my $indexfile = delete $args{'indexfile'};
	my $noindex = delete $args{'noindex'};
	my $xmlfolder = delete $args{'xmlfolder'};
	if (%args) {
		for (keys %args) {
			warn "unrecognized option: $_"
		}
	}

	my $self = {};
   bless ($self, $class);

   unless (defined($xmlfolder)) { $xmlfolder = $self->FindINC('Syntax/Kamelon/XML') };
	unless (defined($indexfile)) { $indexfile = "indexrc" };
	unless (defined($noindex)) { $noindex = 0 };
	$self->{EXTENSIONS} = '';
	$self->{INDEX} = {};
	$self->{INDEXFILE} = $indexfile;
	$self->{XMLFOLDER} = $xmlfolder;
	$self->{XMLPOOL} = {};

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
				my $xml = $self->LoadXML("$folder/$file");
				if (defined $xml) {
					my %options = ();
					my $cl = $xml->Comment;
					for (keys %$cl) {
						my $name = $_;
						my $data = $cl->{$name};
						if ($name =~ /^single/i) {
							$options{'slcomment'} = $data->[0];
						} else {
							$options{'mlcommentstart'} = $data->[0];
							$options{'mlcommentend'} = $data->[1];
						}
					}
					my $l = $xml->Language;
					$index{$l->{name}} = {
						%options,
						file => $file,
						ext =>  $l->{extensions},
						menu => $l->{section},
						mime => $l->{mimetype},
						priority => $l->{priority},
						version => $l->{version},
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
	for (sort keys %$index) {
		my $lang = $_;
		my $extl = $index->{$lang}->{'ext'};
		my @o = split(/;/, $extl);
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

sub ExtensionSyntaxes {
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
	my $i = $self->{INDEX};
	if (exists $p->{$syntax}) {
		return $p->{$syntax}
	} elsif (exists $i->{$syntax}) {
		my $file = $self->{XMLFOLDER} . '/' . $i->{$syntax}->{'file'};
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
	return undef
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

sub InfoPriority {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'priority')
}

sub InfoMLCommentEnd {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'mlcommentend')
}

sub InfoMLCommentStart {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'mlcommentstart')
}

sub InfoSection {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'menu')
}

sub InfoSLComment {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'slcomment')
}

sub InfoVersion {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'version')
}

sub InfoXMLFile {
	my ($self, $syntax) = @_;
	return $self->Info($syntax, 'file')
}

sub LoadIndex {
	my ($self, $noindex) = @_;
	my $file = '';
	unless ($noindex) { $file = $self->XMLFolder . '/' . $self->IndexFile }
	if (-e $file) {
		if (open(OFILE, "<", $file)) {
			local our $re;
			$re = qr{\[ ( (?: (?> [^[\]]+ ) | (??{ $re }) )* ) \]}x;
			my %index = ();
			my $section;
			my %inf = ();
			while (<OFILE>) {
				my $line = $_;
				chomp $line;
				if ($line =~ $re) { #new section
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
	my ($self, $file) = @_;
	return Syntax::Kamelon::XMLData->new(xmlfile => $file)
}

sub SaveIndex {
	my $self = shift;
	my $file = $self->XMLFolder . '/' . $self->IndexFile;
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
	} else {
		warn "cannot open index file $file" 
	}
}

sub SyntaxExists {
	my ($self, $syntax) = @_;
	my $i = $self->{INDEX};
	return exists $i->{$syntax}
}



sub XMLFolder {
	my $self = shift;
	if (@_) { $self->{XMLFOLDER} = shift; }
	return $self->{XMLFOLDER};
}


1;
