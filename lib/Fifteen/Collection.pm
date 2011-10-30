package Fifteen::Collection;

# ABSTRACT: collection of positions
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(:all);
use Moose::Util::TypeConstraints;

has 'data' => (
    is => 'rw',
    isa => HashRef[class_type('Fifteen::Position')],
    traits => ['Hash'],
    handles => {
        list => 'values',
    },
    default => sub { {} },
);

sub add {
    my $self = shift;
    my ($position) = @_;

    $self->data->{ $position->hash } = $position;
}

sub remove {
    my $self = shift;
    my ($position) = @_;

    delete $self->data->{ $position->hash };
}

sub check {
    my $self = shift;
    my ($position) = @_;

    return 1 if $self->data->{ $position->hash };
    return;
}

__PACKAGE__->meta->make_immutable;
