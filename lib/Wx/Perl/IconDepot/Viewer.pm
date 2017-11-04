package Wx::Perl::IconDepot::Viewer;

=head1 NAME

Wx::Perl::IconDepot::Viewer - Display and select icons on a panel

=cut

use Wx qw( :frame :sizer :panel :window :id);
use base qw( Wx::ScrolledWindow );

###############################################################################
=head1 SYNOPSIS

=over 4


=back

=head1 DESCRIPTION


=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

=head1 PUBLIC METHODS

=over 4

=cut


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
