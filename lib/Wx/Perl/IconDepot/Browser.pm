package Wx::Perl::IconDepot::Browser;

use Wx qw( :frame :sizer :panel :window :id);
use base qw( Wx::Panel );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $self->SetSizer($sizer);

    return $self;
}

1;
__END__
