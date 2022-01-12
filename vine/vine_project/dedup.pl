#!/usr/bin/perl

use warnings;
use strict;
use lib qq(./);
use Text::CSV_XS;
use Data::Dumper;
use Date::Manip;
use Vine;
use JSON;
use DB_File;

my $json = JSON->new->allow_nonref;

my $db = 'm2vine.db';

my $vdb = Vine->new( { "database" => $db } );


my $csv_file;
my @line;
my $name;
my $file;

no warnings;
no strict;

my $csv = Text::CSV_XS->new();

open O,">",'/tmp/delete.sql' or die "could not open delete.sql - $!";
$csv_file = '/tmp/m1.csv';

open my $fh, "<:encoding(utf8)", "$csv_file" or die "$csv_file : $!";

my $first_time = 1;
while ( my $row = $csv->getline($fh) ) {
    if ($first_time) {
        $first_time = 0;
        next;
    }
    next unless ( $row->[0] && $row->[0] ne 'No id found');
    @where = ();
    my $sql = qq{select id, IID from names where IID = ?};
    push @where, $row->[0];
    my $sth = $vdb->do_sql( { sql => $sql, where => \@where } );
    my $rec = $sth->fetchrow_hashref();
    if ( $rec ) {
        print "found: ". $row->[0] . " for: ". $rec->{IID}."\n";
        print O " delete from names where id = $rec->{id}\n";
    }
}

close $fh or die "$csv_file : $!";
close O;

exit;


