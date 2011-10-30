package Fifteen::Path;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(:all);
use Moose::Util::TypeConstraints;

has 'positions' => (
    is => 'ro',
    isa => ArrayRef[class_type('Fifteen::Position')],
    traits => ['Array'],
    handles => {
        list => 'elements',
    },
);

# path is immutable, append returns new path object!
sub append {
    my $self = shift;
    my ($tail) = @_; # $tail is a Position object
    return Fifteen::Path->new(positions => [ @{ $self->positions }, $tail ]);
}

has 'hash' => (
    is => 'ro',
    isa => Str,
    lazy_build => 1,
);
sub _build_hash {
    my $self = shift;
    return join '->', map { $_->hash } @{ $self->positions };
}

sub end {
    my $self = shift;
    return @{ $self->positions }[-1];
}

__PACKAGE__->meta->make_immutable;
