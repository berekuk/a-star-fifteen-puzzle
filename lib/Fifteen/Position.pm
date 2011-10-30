package Fifteen::Position;

use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw(:all);

has [qw/ width height /] => (
    is => 'ro',
    isa => Int,
    default => 4,
);

has 'board' => (
    is => 'ro',
    isa => ArrayRef[ArrayRef[Int]],
    required => 1,
);

sub BUILD {
    my $self = shift;

    # check board size
    die 'Invalid board: width = '.scalar(@{$self->board})
        unless @{$self->board} == $self->width;

    # check size of every column
    for (0 .. $self->width - 1) {
        die "Invalid board: height(row $_) = ".scalar @{$self->board->[$_]}
            unless @{$self->board->[$_]} == $self->height;
    }
    # TODO - validate board content too
}

sub print {
    my $self = shift;
    print $self->as_string;
}

sub as_string {
    my $self = shift;
    my $result = '';
    for my $x (0 .. $self->width - 1) {
        for my $y (0 .. $self->height - 1) {
            my $item = $self->board->[$x][$y];
            if ($item > 0) {
                $result .= sprintf "%2d ", $item;
            }
            else {
                $result .= "   ";
            }
        }
        $result .= "\n";
    }
    return $result;
};

sub empty_coordinates {
    my $self = shift;

    my ($empty_x, $empty_y);
    SEARCH: for my $x (0 .. $self->width - 1) {
        for my $y (0 .. $self->height - 1) {
            if ($self->board->[$x][$y] == 0) {
                ($empty_x, $empty_y) = ($x, $y);
                last SEARCH;
            }
        }
    }
    die "Can't find empty cell" unless defined $empty_x;
    return ($empty_x, $empty_y);
}

sub turn_options {
    my $self = shift;

    # first, lets find empty cell
    my ($empty_x, $empty_y) = $self->empty_coordinates;

    my @moves = (
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1],
    );

    my $is_valid = sub {
        my ($x, $y) = @_;
        return if $x < 0;
        return if $y < 0;
        return if $x >= $self->width;
        return if $y >= $self->height;
        return 1;
    };

    my $copy_board = sub {
        my $board = [
            map { [ @{ $self->board->[$_] } ] } 0 .. $self->width - 1
        ];
        return $board;
    };

    # generate new position for each valid move
    my @positions;
    for my $move (@moves) {
        my ($move_x, $move_y) = ($empty_x + $move->[0], $empty_y + $move->[1]);
        next unless $is_valid->($move_x, $move_y);

        my $new_board = $copy_board->();
        $new_board->[$empty_x][$empty_y] = $new_board->[$move_x][$move_y];
        $new_board->[$move_x][$move_y] = 0;
        push @positions, Fifteen::Position->new(
            board => $new_board,
            width => $self->width,
            height => $self->height,
        );
    }
    return @positions;
}

sub hash {
    my $self = shift;
    return join '|', map {
        join ',', @$_
    } @{ $self->board };
}

__PACKAGE__->meta->make_immutable;
