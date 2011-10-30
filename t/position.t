#!/usr/bin/perl

use strict;
use warnings;
use v5.012;

use Test::More 0.95;

use lib 'lib';

use_ok 'Fifteen::Position';
use Fifteen;

is(
    Fifteen->new->target_position->hash,
    '1,2,3,4|5,6,7,8|9,10,11,12|13,14,15,0'
);

done_testing;
