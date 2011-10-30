package Fifteen;

use v5.012;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(:all);

use Fifteen::Position;
use List::Util qw( shuffle );
use List::MoreUtils qw( first_index indexes );

has [qw/ width height /] => (
    is => 'ro',
    isa => Int,
    default => 4,
);

sub _items_to_position {
    my $self = shift;
    my @items = @_;

    my $board = [
        map { [
            @items[ $_ * $self->height .. ($_ + 1) * $self->height - 1 ]
        ] } 0 .. $self->width - 1
    ];
    return Fifteen::Position->new(
        board => $board,
        width => $self->width,
        height => $self->height,
    );
}

sub _target_items {
    my $self = shift;
    return (1 .. $self->width * $self->height - 1, 0);
}

sub _permutation_parity {
    my $self = shift;
    my @items = @_;
    my @targets = $self->_target_items;

    my $total = 0;
    for my $target_id ( 0 .. @targets - 1 ) {
        my $target_value = $targets[$target_id];
        my $item_value = $items[$target_id];
        next if $target_value == $item_value;

        # transpose
        my $item_id = first_index { $_ == $target_value } @items;
        $items[$item_id] = $item_value;
        $items[$target_id] = $target_value;
        $total++;
    }
    return $total;
}

sub random_position {
    my $self = shift;

    my @items = shuffle 0 .. $self->width * $self->height - 1;
    my $position = $self->_items_to_position(@items);

    # check if position is solvable
    # position is solvable if parity + taxicab distance of empty item is even
    my $parity = $self->_permutation_parity(@items);
    my ($empty_x, $empty_y) = $position->empty_coordinates;
    my $empty_taxicab_distance = (
        abs($empty_x - ($self->width - 1))
        + abs($empty_y - ($self->height - 1))
    );
    if (($parity + $empty_taxicab_distance) % 2) {
        # swap first two non-empty items
        my ($first_id, $second_id) = indexes { $_ > 0 } @items;
        ($items[$first_id], $items[$second_id]) = ($items[$second_id], $items[$first_id]);
        $position = $self->_items_to_position(@items);
    }
    return $position;
}

sub target_position {
    my $self = shift;

    return $self->_items_to_position($self->_target_items);
}

__PACKAGE__->meta->make_immutable;
