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

my $new_db = $ARGV[0] || 0;

my $vdb;
if ($new_db) {
    $vdb = Vine->new( { "database" => $new_db } );
}
else {
    $vdb = Vine->new();
}

my $prefix = '/home/jozefn/data/';

my $csv_file;
my @line;
my $name;
my $file;

no warnings;
no strict;

format FILELOAD =
===========================================================================================
    File                          Found Facility  Insert Facility  Found Names Insert Names
@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<  @<<<<           @<<<<            @<<<<       @<<<<
$file,$found_facility,$insert_facility,$found_names,$insert_names
===========================================================================================
.

select(STDOUT);
$~ = FILELOAD;

my $total_names_found = 0;

my $today = `date`;
my $date_time = UnixDate( $today, "%Y%m%d-%H:%M" );

my $csv = Text::CSV_XS->new();
my $zip;

my $dbfile = 'facility.db';
my %hash;
tie %hash, "DB_File", $dbfile
  or die "Can't open $dbfile: $!\n";

build_facility_db(%hash);

untie %hash;

tie %hash, "DB_File", $dbfile
  or die "Can't open $dbfile: $!\n";

my $cnt = 0;
opendir( my $dh, $prefix ) || die "Can't open $prefix: $!";
while ( $file = readdir $dh ) {
    next if ( $file =~ /^\.+/ );
    chomp $file;
    next unless ( $file =~ /\.csv$/ );

    $csv_file = $prefix . $file;

    open my $fh, "<:encoding(utf8)", "$csv_file" or die "$csv_file : $!";

    my @where;
    my $id;
    my $first_time = 1;
    $found_facility  = 0;
    $insert_facility = 0;
    $found_names     = 0;
    $insert_names    = 0;

    while ( my $row = $csv->getline($fh) ) {
        if ($first_time) {
            $first_time = 0;
            next;
        }
        @where = ();
        next
          if ( $row->[1] =~
            /California\s*Department\s*of\s*Corrections\s*and\s*Rehabilitation/i
          );
        my $sql = qq{select id from facility where name = ?};
        push @where, $row->[1];
        my $sth = $vdb->do_sql( { sql => $sql, where => \@where } );
        my $rec = $sth->fetchrow_hashref();
        if ( !$rec ) {
            my $name = $row->[1];
            $name =~ s/^\s+//;
            $name =~ s/\s+$//;
            $name =~ s/\s+/ /g;
            my $key = $name;
            $key =~ s/[^a-zA-Z]+//g;
            my $json_rec = $hash{$key};
            if ($json_rec) {
                my $r    = $json->decode($json_rec);
                my @keys = sort keys %{$r};
                my $cols = join ',', @keys;
                foreach my $key ( sort keys %{$r} ) {
                    push @where, $r->{key};
                }
                my $qmarks = '?,' x ( scalar @where );
                $qmarks =~ s/,$//;
                $sql = qq{insert into facility ($cols) values ($qmarks)};
            }
            else {
                $sql = qq{insert into facility (name) values (?)};
            }
            $sth = $vdb->do_sql( { sql => $sql, where => \@where } );
            $id = $vdb->last_inserted_id();
            $insert_facility++;
        }
        else {
            $id = $rec->{id};
            $found_facility++;
        }
        @where = ();
        $sql   = qq{select * from names where IID = ?};
        push @where, $row->[2];
        $sth = $vdb->do_sql( { sql => $sql, where => \@where } );
        $rec = $sth->fetchrow_hashref();
        if ( !$rec ) {
            @where = ();
            push @where, $id;
            push @where, $row->[0];
            push @where, $row->[2];
            push @where, $row->[3];
            push @where, $date_time;
            my ($l) = ( $file =~ /^([a-zA-Z]+)_/ );
            push @where, "$l";

            #bypass cdcr numbers and out of custody
            unless ( ( $id == 2 )
                or ( $row->[3] eq 'Out of Custody' )
                or ( $row->[3] eq 'Transferred' ) )
            {
                $sql =
qq{insert into names(facility,name,IID,status,cdate,mdate) values (?,?,?,?,?,?)};
                $sth = $vdb->do_sql( { sql => $sql, where => \@where } );
                $insert_names++;
            }
        }
        else {
            $found_names++;
        }

    }
    close $fh or die "$csv_file : $!";
    write;
}

untie %hash;
closedir $dh;

my $sth = $vdb->do_sql(
    { sql => 'select count(*) as total_facility from facility where id != 2;' }
);
my $rec            = $sth->fetchrow_hashref();
my $total_facility = $rec->{total_facility};
my $sth =
  $vdb->do_sql( { sql => 'select count(*) as total_names from names;' } );
my $rec               = $sth->fetchrow_hashref();
my $total_names_found = $rec->{total_names};

print "=========================================================\n";
print
"\t\t\tTotal Names to date: $total_names_found in $total_facility facilities\n";
print "=========================================================\n";

exit;

sub build_facility_db {

    my $first_time = 1;
    $csv_file = 'Z3_county.csv';
    open my $fh, "<:encoding(utf8)", "$csv_file" or die "$csv_file : $!";
    while ( my $row = $csv->getline($fh) ) {
        if ($first_time) {
            $first_time = 0;
            next;
        }
        my $name = $row->[0];
        $name =~ s/^\s+//;
        $name =~ s/\s+$//;
        $name =~ s/\s+/ /g;
        my $key = $name;
        $key =~ s/[^a-zA-Z]+//g;
        my %rec;
        $rec{name}    = '';
        $rec{address} = '';
        $rec{city}    = '';
        $rec{county}  = '';
        $rec{zip}     = '';
        $rec{website} = '';
        my $n    = $row->[0];
        my $a    = $row->[2];
        my $c    = $row->[3];
        my $cnty = $row->[4];
        my $z    = $row->[5];
        my $w    = $row->[6];

        $rec{name}    = $n;
        $rec{address} = $a;
        $rec{city}    = $c;
        $rec{county}  = $cnty;
        $rec{zip}     = $z;
        $rec{website} = $w;
        $json_text    = $json->encode( \%rec );
        $hash{$key}   = $json_text;
    }
    close $fh or die "$csv_file : $!";
}

