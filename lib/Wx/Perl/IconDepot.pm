package Wx::Perl::IconDepot;

=head1 NAME

Wx::Perl::IconDepot - Handle icon libraries quick & easy

=cut

use strict;
use warnings;

use vars qw($VERSION);
our $VERSION = '0.01';

use Wx qw( :image );
use File::Basename;
use Module::Load::Conditional qw( check_install );

my @subfolder_ignore = qw( cursors );

my %imgext = (
	'.jpg' => wxBITMAP_TYPE_JPEG,
	'.jpeg' => wxBITMAP_TYPE_JPEG,
	'.png' => wxBITMAP_TYPE_PNG,
	'.gif' => wxBITMAP_TYPE_GIF,
	'.bmp' => wxBITMAP_TYPE_BMP,
	'.xpm' => wxBITMAP_TYPE_XPM,
);
my @extensions = (keys %imgext);

if (check_install( module => 'Image::LibRSVG' )) {
	push @extensions, '.svg';
	use Image::LibRSVG;
	use IO::Scalar;
}


my @iconpath = ();
if ($^O eq 'MSWin32') {
	push @iconpath, $ENV{ALLUSERSPROFILE} . '\Icons'
} else {
	push @iconpath, $ENV{HOME} . '/.local/share/icons',
	push @iconpath, '/usr/share/icons',
}

=head1 SYNOPSIS

=over 4

 my $depot = new Wx::Perl::IconDepot(@pathnames);
 $depot->SetThemes($theme1, $theme2, $theme3);
 my $wxbitmap = $depot->GetBitmap($name, $size, $context)
 my $wxicon = $depot->GetIcon($name, $size, $context)
 my $wximage = $depot->GetImage($name, $size, $context)

=back

=head1 DESCRIPTION

=cut

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};
   bless ($self, $class);

   my $pathlist = shift;
   unless (defined $pathlist) { $pathlist = \@iconpath };

   $self->{DEFAULTSIZE} = 22;
   $self->{FORCEIMAGE} = 1;
   $self->{INDEX} = undef;
	$self->{ICONPATH} = $pathlist;
	$self->{MISSINGIMAGE} = $self->FindINC('Wx/Perl/IconDepot/image_missing.png');
	$self->{THEMEPOOL} = {};
	$self->{THEMES} = $self->CollectThemes;
	Wx::InitAllImageHandlers();
	return $self;
}

=head1 PUBLIC METHODS

=over 4

=item B<AvailableThemes>

=over 4

Returns a list of available themes it found while initiating the module.

=back

=cut

sub AvailableThemes {
	my $self = shift;
	my $k = $self->{THEMES};
	return sort keys %$k
}

=item B<FindImage>I<($name, $size, $context, \$resize)>

=over 4

Returns the filename of an image in the library. Finds the best suitable version of
the image in the library according to $size and $context. If it eventually returns
an image of another size, it sets $resize to 1. This gives the opportunity to scale
the image to the right icon size. All parameters except $name are optional.

=back

=cut

sub FindImage {
	my ($self, $name, $size, $context, $resize) = @_;
	unless (defined $size) { $size = 'unknown' }
	unless (defined $context) { $context = 'unknown' }
	my $active = $self->{ACTIVE};
	for (@$active) {
		my $index = $_;
		if (exists $index->{$name}) {
			return $self->FindImageS($index->{$name}, $size, $context, $resize);
		}
	}
	return undef;
}

=item B<GetBitmap>I<($name, $size, $force)>

=over 4

Returns a Wx::Bitmap object. If you do not specify I<$size> or the icon does not exist in the specified size, it will return the largest
possible icon. I<$force> can be 0 or 1. It is 0 by default. If you set it to 1 a missing icon image is returned instead of undef when the icon cannot be
found.

=back

=cut

sub GetBitmap {
	my $self = shift;
	return Wx::Bitmap->new($self->GetImage(@_))
}

=item B<GetIcon>I<($name, $size, $force)>

=over 4

Returns a Wx::Icon object. If you do not specify I<$size> or the icon does not exist in the specified size, it will return the largest
possible icon. I<$force> can be 0 or 1. It is 0 by default. If you set it to 1 a missing icon image is returned instead of undef when the icon cannot be
found.

=back

=cut

sub GetIcon {
   my $self = shift;
	my $bmp = $self->GetBitmap(@_);
	my $icon = Wx::Icon->new();
	$icon->CopyFromBitmap($bmp);
	return $icon
}

=item B<GetImage>I<($name, $size, $force)>

=over 4

Returns a Wx::Image object. If you do not specify I<$size> or the icon does not exist in the specified size, it will find the largest
possible icon and scale it to the requested size. I<$force> can be 0 or 1. It is 0 by default. If you set it to 1 a missing icon 
image is returned instead of undef when the icon cannot be found.

=back

=cut

sub GetImage {
   my ($self, $name, $size, $context, $force) = @_;
   unless (defined $force) { $force = 0 }
   my $resize = 0;
	my $file = $self->FindImage($name, $size, $context, \$resize);
	if (defined $file) { 
		my $img = $self->LoadImage($file, $size);
		if ($img->IsOk) {
			if ($resize) {
				return $img->Scale($size, $size);
			}
			return $img
		} else {
			return undef
		}
	} elsif ($force and (defined $size) and ($size =~ /^\d+$/)) { #size must be defined and numeric
		return $self->GetMissingImage($size)
	}
	return undef
}

=item B<GetThemePath>I<($theme)>

=over 4

Returns the full path to the folder containing I<$theme>

=back

=cut

sub GetThemePath {
	my ($self, $theme) = @_;
	my $t = $self->{THEMES};
	if (exists $t->{$theme}) {
		return $t->{$theme}->{path}
	} else {
		warn "Icon theme $theme not found"
	}
}

=item B<IsImageFile>I<($file)>

=over 4

Returns true if I<$file> is an image. Otherwise returns false.

=back

=cut

sub IsImageFile {
	my ($self, $file) = @_;
	unless (-f $file) { return 0 } #It must be a file
	my ($d, $f, $e) = fileparse(lc($file), @extensions);
	if ($e ne '') { return 1 }
	return 0
}

=item B<LoadImage>I<($file)>

=over 4

Loads image I<$file> and returns it as a Wx::Image object.

=back

=cut

sub LoadImage {
   my ($self, $file, $size) = @_;
   if (-e $file) {
		my ($name,$path,$suffix) = fileparse(lc($file), @extensions);
		if (exists $imgext{$suffix}) {
			my $type = $imgext{$suffix};
			my $img = Wx::Image->new($file, $type);
			if ($img->IsOk) {
				return $img
			}
		} elsif ($suffix eq '.svg') {
			my $renderer = Image::LibRSVG->new;
			$renderer->loadFromFileAtSize($file, $size, $size);
			my $png = $renderer->getImageBitmap("png", 100);
			my $img = Wx::Image->newStreamType(IO::Scalar->new(\$png), wxBITMAP_TYPE_PNG);
			if ($img->IsOk) {
				return $img
			}
		} else {
			warn "could not define image type for file $file"
		}
   }  else {
      warn "image file $file not found \n";
   }
   return undef
}

=item B<SetThemes>I<($theme1, $theme2, $theme3)>

=over 4

Initializes themes. I<$theme1> is the primary theme. The rest are subsequent fallback themes. Suggestion
to use your favourite theme as the first one and the theme that has the most icons as the last one.

=back

=cut

sub SetThemes {
	my $self = shift;
	my @activenames = ();
	my @active = ();
	for (@_) {
		push @activenames, $_;
		push @active, $self->GetTheme($_);
	}
	$self->{ACTIVENAMES} = \@activenames;
	$self->{ACTIVE} = \@active;
}

=back

=head1 PRIVATE METHODS

=over 4

=item B<CollectThemes>

Called during initialization. It scans the folders the constructor receives for icon libraries.
It loads their index files and stores the info.

=over 4

=back

=cut

sub CollectThemes {
	my $self = shift;
	my %themes = ();
	my $iconpath = $self->{ICONPATH};
	for (@$iconpath) {
		my $dir = $_;
		if (opendir DIR, $dir) {
			while (my $entry = readdir(DIR)) {
				my $fullname = "$dir/$entry";
				if (-d $fullname) {
					if (-e "$fullname/index.theme") {
						my $index = $self->LoadThemeFile($fullname);
						my $main = delete $index->{'Icon Theme'};
						if (%$index) {
							my $name = $entry;
							if (exists $main->{Name}) {
								$name = $main->{Name}
							}
							$themes{$name} = {
								path => $fullname,
								general => $main,
								folders => $index,
							}
						}
					}
				}
			}
			closedir DIR;
		}
	}
	return \%themes
}

=item B<CreateIndex>I<($themeindex)>

=over 4

Creates a searchable index from a loaded theme index file. returns a reference to a hash.

=back

=cut

sub CreateIndex {
	my ($self, $tindex) = @_;
	my %index = ();
	my $base = $tindex->{path};
	my $folders = $tindex->{folders};
	foreach my $dir (keys %$folders) {
		my @raw = <"$base/$dir/*">;
		foreach my $file (@raw) {
			if ($self->IsImageFile($file)) {
				my ($name, $d, $e) = fileparse($file, @extensions);
				unless (exists $index{$name}) {
					$index{$name} = {}
				}
				my $size = $folders->{$dir}->{Size};
				unless (defined $size) {
					$size = 'unknown';
				}
				unless (exists $index{$name}->{$size}) {
					$index{$name}->{$size} = {}
				}
				my $context = $folders->{$dir}->{Context};
				unless (defined $context) {
					$context = 'unknown';
				}
				$index{$name}->{$size}->{$context} = $file;
			}
		}
	}
	return \%index;
}

=item B<FindImageC>I<($sizeindex, $context)>

=over 4

Looks for an icon in $context for a given size index (a portion of a searchable index). If it can not find it
it looks for another version in all other contexts. Returns the first one it finds.

=back

=cut

sub FindImageC {
	my ($self, $si, $context) = @_;
	if (exists $si->{$context}) {
		return $si->{$context}
	} else {
		my @contexts = sort keys %$si;
		if (@contexts) {
			return $si->{$contexts[0]};
		}
	}
	return undef
}

=item B<FindImageS>I<($nameindex, $size, $context)>

=over 4

Looks for an icon of $size for a given name index (a portion of a searchable index). If it can not find it
it looks for another version in all other sizes. Returns the biggest one it finds.

=back

=cut

sub FindImageS {
	my ($self, $nindex, $size, $context, $resize) = @_;
	if (exists $nindex->{$size}) {
		my $file = $self->FindImageC($nindex->{$size}, $context);
		if (defined $file) { return $file }
	} else {
		if (defined $resize) { $$resize = 1 }
		my @sizes = reverse sort keys %$nindex;
		for (@sizes) {
			my $si = $nindex->{$_};
			my $file = $self->FindImageC($si, $context);
			if (defined $file) { return $file }
		}
	}
	return undef
}

=item B<FindINC>I<($file)>

=over 4

Looks for a file in @INC. if found returns the full pathname.

=back

=cut

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

=item B<GetMissingImage>I<($size)>

=over 4

Returns a Wx::Image object of the missing image symbal on the requested size.

=back

=cut

sub GetMissingImage {
	my ($self, $size) = @_;
	my $tmp = Wx::Image->new($self->{MISSINGIMAGE}, wxBITMAP_TYPE_PNG, );
	return $tmp->Scale($size, $size, wxIMAGE_QUALITY_HIGH)
}

=item B<GetTheme>I<($themename)>

=over 4

Looks for a searchable index of the theme. If it is not yet created it will
be created first and stored in the index pool.

=back

=cut

sub GetTheme {
	my ($self, $theme) = @_;
	my $pool = $self->{THEMEPOOL};
	if (exists $pool->{$theme}) {
		return $pool->{$theme}
	} else {
		my $themindex = $self->{THEMES}->{$theme};
		if (defined $themindex) {
			my $index = $self->CreateIndex($themindex);
			$pool->{$theme} = $themindex;
			return $index
		} else {
			warn "Setting theme '$theme' failed"
		}
	}
}

=item B<LoadThemeFile>I<($file)>

=over 4

Loads a theme index file and returns the information in it in a hash.
It returns a reference to this hash.

=back

=cut

sub LoadThemeFile {
	my ($self, $file) = @_;
	if (defined $file) {
		$file = "$file/index.theme";
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
			return \%index;
		} else {
			warn "Cannot open theme index file: $file"
		}
	}
}

=back

=head1 AUTHOR

Hans Jeuken (hansjeuken at xs4all dot nl)

=head1 BUGS

If you find any, please contact the author.

Icon libararies that depend on .svg images are shown in the list of I<AvailableThemes>.
However they are useless. It cannot be prevented without heavy delving into the icon libary
itself, which would impose a start up penalty.

=head1 TODO

Add support for .svg icons.

=cut

1;
__END__
