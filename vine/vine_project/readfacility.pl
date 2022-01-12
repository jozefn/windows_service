#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use lib qw(./);
use Vine;
use JSON;

my $json = JSON->new->allow_nonref;


my $vdb = Vine->new();

use DB_File;
my $dbfile = 'facility.db';
my %hash;
tie %hash, "DB_File", $dbfile 
       or die "Can't open $dbfile: $!\n";


foreach my $key ( keys %hash ){
    my $rec = $hash{$key};
    my $r = $json->decode($rec);

}

die();

my $sql = qq{select id, name from facility};
my $sth = $vdb->do_sql({ sql=>$sql });
while ( my $rec = $sth->fetchrow_hashref()){
    my $name = $rec->{name};
    $name =~ s/^\s+//;
    $name =~ s/\s+$//;
    $name =~ s/\s+/ /g;
    my $key = $name;
    $key =~ s/[^a-zA-Z]+//g;
    if ( exists $hash{$key} ){
        print Dumper($hash{$key});
    } else {
        print "$key\n";
    }
}

untie %hash;     


