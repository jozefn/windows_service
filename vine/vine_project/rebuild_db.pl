#!/usr/bin/perl
use warnings;
use strict;
use lib qq(./);
use Data::Dumper;
use Vine;

my $new_db = 'mytest.db';
my $vdb = Vine->new({ "database" => $new_db });



