package Wx::Perl::IconDepot::Browser;

=head1 NAME

Wx::Perl::IconDepot::Browser - Browse icon libraries quick & easy

=cut

use strict;
use warnings;

use Wx qw( :frame :sizer :panel :window :id);
use base qw( Wx::Panel );
use Wx::Perl::IconDepot::Viewer;

###############################################################################
=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION


=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $sizer = Wx::BoxSizer->new(wxVERTICAL);
	$self->SetSizer($sizer);

	my $navigator = Wx::Panel->new($self, -1);
	$sizer->Add($navigator, 0, wxEXPAND);
	my $nsiz = Wx::BoxSizer->new(wxHORIZONTAL);
	$navigator->SetSizer($nsiz);
	
	my $ttext = Wx::StaticText->new($navigator, -1, 'Theme:');
	$nsiz->Add($ttext, 0, wxALIGN_CENTER_VERTICAL|wxALL, 2 );
	my $tcom = Wx::ComboBox->new($navigator, -1);
	$nsiz->Add($tcom, 1, wxALL, 2);

	my $stext = Wx::StaticText->new($navigator, -1, 'Size:');
	$nsiz->Add($stext, 0, wxALIGN_CENTER_VERTICAL|wxALL, 2  );
	my $scom = Wx::ComboBox->new($navigator, -1);
	$nsiz->Add($scom, 1, wxALL, 2);

	my $ctext = Wx::StaticText->new($navigator, -1, 'Context:');
	$nsiz->Add($ctext, 0, wxALIGN_CENTER_VERTICAL|wxALL, 2  );
	my $ccom = Wx::ComboBox->new($navigator, -1);
	$nsiz->Add($ccom, 1, wxALL, 2);


	my $viewer = Wx::Perl::IconDepot::Viewer->new($self, -1);
	$sizer->Add($viewer, 1, wxEXPAND);
	$self->Layout;
	$self->Fit;
	return $self;
}

###############################################################################
=back

=head1 PRIVATE METHODS

=over 4

=cut


###############################################################################
=back

=head1 AUTHOR

Hans Jeuken (hansjeuken at xs4all dot nl)

=head1 BUGS

If you find any, please contact the author.

Icon libararies that depend on .svg images show up in the list of 
B<AvailableThemes> when no support for scalable vector graphics is available.

=head1 TODO

=cut

1;
__END__
