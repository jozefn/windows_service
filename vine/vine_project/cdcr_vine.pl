#!/usr/bin/perl

use warnings;
use strict;
use lib qw(./);
use Data::Dumper;
use JSON;
use Vine;


my $vdb = Vine->new();

my $facility_id = 2;
my $sql = qq{ select id,IID from names where facility = $facility_id};

my $sth = $vdb->do_sql({sql => $sql});

while ( my $rec =  $sth->fetchrow_hashref()){
    print Dumper($rec);
}




exit;


