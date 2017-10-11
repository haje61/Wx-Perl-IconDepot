
use strict;
use warnings;

use Test::More tests => 3;
BEGIN { use_ok('Wx::Perl::IconDepot') };

my $theme = 'Humanity';
my @icons = qw( go-first go-last go-top go-bottom edit-cut edit-copy edit-paste application-exit );
my $size = 22;

use Wx;

my $depot = new Wx::Perl::IconDepot;
ok (defined $depot, "creation");

my @avthemes = $depot->AvailableThemes;
print "Available themes:\n";
for (@avthemes) { print "$_\n" }

$depot->SetThemes($theme);
ok(1, "setting theme");

my $file = $depot->FindImage('edit-cut', 22);
print "found $file\n";


package MyIconFrame;
use Wx qw( :frame :textctrl :sizer :panel :window :id);
use base qw( Wx::Frame );
use Wx::Event qw( EVT_BUTTON );

sub new {
    my($class, $parent) = @_;
    my $self = $class->SUPER::new(
        $parent,
        -1,
        'Example Frame',
        [-1,-1],
        [-1,-1],
        wxDEFAULT_FRAME_STYLE 
	);
	my $sizer = Wx::FlexGridSizer->new(0, 8, 10, 10);
	$self->SetSizer($sizer);
	for (@icons) {
		my $si = Wx::StaticBitmap->new($self, -1, $depot->GetBitmap($_, $size, undef, 1));
		$sizer->Add($si);
# 		print "bitmap $_\n";
	}
	for (@icons) {
# 		print "icon $_\n";
		my $si = Wx::StaticBitmap->new($self, -1, $depot->GetIcon($_, $size, undef, 1));
		$sizer->Add($si);
	}
	for (@icons) {
# 		print "image $_\n";
		my $si = Wx::StaticBitmap->new($self, -1, Wx::Bitmap->new($depot->GetImage($_, $size, undef, 1)));
		$sizer->Add($si);
	}
	$self->Layout;
	$self->Fit;
	return $self;
}


package IconDepotTest;

use base qw(Wx::App);   # Inherit from Wx::App

sub OnInit
{
   my $self = shift;
   my $frame = MyIconFrame->new;
   $self->SetTopWindow($frame);    # Define the toplevel window
   $frame->Show(1);                # Show the frame
}

package main;

my $wxobj = IconDepotTest->new(); # New HelloWorld application
$wxobj->MainLoop;
