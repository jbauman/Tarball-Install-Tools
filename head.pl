#!/usr/bin/perl

use strict;
use warnings;
use Fatal qw(open close);

my $data = do { local $/; <DATA>; };
open(my $PIPE, "|gunzip - | tar xvf -");
print {$PIPE} $data;
close($PIPE);
# your script goes here


__DATA__
