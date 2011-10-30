#!/usr/bin/env perl

use v5.014;
use namespace::autoclean;
use Moose;
with 'MooseX::Getopt::Strict';

use lib 'lib';

use MooseX::Types::Moose qw(:all);
use Fifteen::Collection;
use Fifteen::Path;
use Fifteen;

has [qw/ width height /] => (
    is => 'ro',
    isa => Int,
    default => 4,
    traits => ['Getopt'],
);

has 'verbose' => (
    is => 'ro',
    isa => Bool,
    traits => ['Getopt'],
);

has 'fifteen' => (
    is => 'ro',
    isa => 'Fifteen',
    lazy => 1,
    default => sub {
        my $self = shift;
        Fifteen->new(width => $self->width, height => $self->height),
    },
);

has 'target_position' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->fifteen->target_position;
    },
);

has 'estimate_weight' => (
    is => 'ro',
    isa => Int,
    default => 1,
    traits => ['Getopt'],
    cmd_flag => 'weight',
);

sub cost {
    my $self = shift;
    my ($path) = @_;

    my @positions = $path->list;
    return scalar @positions;
}

# this is a hashref { 1 => [0,0], 2 => [1,0], ... }
# it's used by estimate() for faster estimating
has '_target_coords' => (
    is => 'ro',
    isa => HashRef[ArrayRef[Int]],
    lazy => 1,
    default => sub {
        my $self = shift;
        my $p = $self->target_position;
        my $result;
        for my $x (0 .. $p->width - 1) {
            for my $y (0 .. $p->height - 1) {
                $result->{ $p->board->[$x][$y] } = [ $x, $y ];
            }
        }
        return $result;
    },
);
sub estimate {
    my $self = shift;
    my ($path) = @_;

    my $p = $path->end;
    my $target = $self->_target_coords;
    my $board = $p->board;
    my $width = $p->width;
    my $height = $p->height;

    my $result = 0;
    for my $x (0 .. $width - 1) {
        for my $y (0 .. $height - 1) {
            my $target_coords = $target->{$board->[$x][$y]};
            $result += abs($x - $target_coords->[0]);
            $result += abs($y - $target_coords->[1]);
        }
    }
    die "estimate is odd" if $result % 2;
    return $result / 2;
}

sub print_br {
    my $self = shift;
    say '-' x 30;
}

sub total_cost {
    my $self = shift;
    my ($path) = @_;

    return $self->cost($path) + $self->estimate($path) * $self->estimate_weight;
}

sub main {
    my $self = shift;

    my $start = $self->fifteen->random_position;
    my $target = $self->target_position;

    $start->print;

    # explored and frontier are collections of *positions*
    my $explored = Fifteen::Collection->new;
    my $frontier = Fifteen::Collection->new;
    $frontier->add($start);

    # array of arrays of paths, with path cost being index
    my @path_buckets;
    my $min_bucket;
    my $update_min_bucket = sub {
        for my $i (0 .. $#path_buckets) {
            if ($path_buckets[$i] and @{ $path_buckets[$i] }) {
                $min_bucket = $i;
                return 1; # it's ok, we found non-empty bucket
            }
        }
        undef $min_bucket; # no paths left!
    };
    {
        my $start_path = Fifteen::Path->new(positions => [$start]);
        push @{ $path_buckets[ $self->total_cost($start_path) ] }, $start_path;
        $update_min_bucket->();
    }

    my $solution;
    my $i = 0;
    while (1) {
        $i++;

        die 'Solution not found' unless defined $min_bucket;

        my $bucket = $path_buckets[$min_bucket];
        my $path = shift $bucket;
        unless (@$bucket) {
            $update_min_bucket->();
        }
        $frontier->remove($path->end);
        $explored->add($path->end);

        if ($self->verbose or not $i % 1000) {
            say "cost: ".$self->cost($path)
                .", estimate: ".$self->estimate($path)
                .", frontier: ".scalar($frontier->list)
                .", explored: ".scalar($explored->list);
        }

        if ($target->hash eq $path->end->hash) {
            # $path is the shortest path
            $solution = $path;
            last;
        }

        for my $option ($path->end->turn_options) {
            next if $explored->check($option);
            next if $frontier->check($option);

            my $new_path = $path->append($option);
            my $cost = $self->total_cost($new_path);
            push @{ $path_buckets[$cost] }, $new_path;
            if (not defined $min_bucket or $cost < $min_bucket) {
                $min_bucket = $cost;
            }

            $frontier->add($option);
        }
    }

    say "Solution found in $i steps, length ".scalar($solution->list).":";
    for my $position ($solution->list) {
        $position->print;
        $self->print_br;
    }
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->new_with_options->main unless caller;

