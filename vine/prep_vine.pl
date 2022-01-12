#!C:\Strawberry\perl\bin\perl.exe

=pod

=head1 prep_vine.pl

does the following:

=over 4

=item  if no values are passed in - reads the json directory and produces the move shell script and the remove shell script. the move shell script moves built json to the ui.vision macro directory for scrap of vine website.

=item if opt value of 1 and to and from generic search keys are passed in, uses template of json used by ui.vision to build new json for the generic search keys.

=back

=cut

use warnings;
use strict;
use Text::CSV_XS;
use Data::Dumper;
use File::Slurp;
use Getopt::Std;
use JSON;
use Date::Manip;

use DB_File;

my $csv_file;
my @line;
my $name;
my $file          = './vine.tmp';
my $prefix        = 'vine';
my $json_location = './json/';

if (! -e $json_location ){
    mkdir $json_location;
}
my %o;
getopts( 'bsmrf:t:', \%o );
if ( !%o ) {
    help();
    exit;
}

if ( $o{s} && ( !$o{t} ) ) {
    help();
    exit;
}
if ( ( $o{m} || $o{r} ) && ( !$o{f} && !$o{t} ) ) {
    help();
    exit;
}

if ( ( $o{m} || $o{r} ) && ( $o{f} && $o{t} ) ) {
    if ( $o{f} ge $o{t} ) {
        help();
        exit;
    }
}

my $letter_hash;
my @final_lines = ();

if ( $o{s} ) {
    @final_lines = ();
    push @final_lines, "\n";
    my $l = $o{t};
    @final_lines = process_file($l);
    my $final_file = $json_location . $prefix . $l . ".json";
    write_file( $final_file, @final_lines );
}
elsif ( $o{m} ) {
    @final_lines = ();
    push @final_lines, "\n";
    my $letter = $o{f};
    while ( $letter ne $o{t} ) {
        @final_lines = process_file($letter);
        push @final_lines, "\n";
        my $final_file = $json_location . $prefix . $letter . ".json";
        $letter++;
        write_file( $final_file, @final_lines );
    }
}
elsif ( $o{r} ) {
    @final_lines = ();
    push @final_lines, "\n";
    if ( ( length $o{f} ) > 3 ) {
        my @v = ( 'A', 'E', 'I', 'O', 'U' );
        for my $l ( $o{f} ... $o{t} ) {
            my @l1 = split //, $l;
            my $chkl = pop @l1;
            if ( my ($matched) = grep $_ eq $chkl, @v ) {
                if ( exists $letter_hash->{$l} ) {
                    $letter_hash->{$l}++;
                }
                else {
                    $letter_hash->{$l} = 1;
                }
            }
        }
    }
    foreach my $l ( keys %{$letter_hash} ) {
        @final_lines = process_file($l);
        my $final_file = $json_location . $prefix . $l . ".json";
        write_file( $final_file, @final_lines );
    }
}
elsif ( $o{m} ) {
    move_files($json_location);
}


exit;

sub process_file {
    my $letter      = shift;
    my @tlines      = read_file($file);
    my @final_lines = ();
    for my $t (@tlines) {
        chomp $t;
        $t =~ s/%%letter%%/$letter/g;
        my $l = "$t\n";
        push @final_lines, $l;
    }
    return @final_lines;
}

sub move_files {
    my $location = shift;
    my $file_cnt = 0;
    my $ui_location = 'c:/Users/jozef/OneDrive/Desktop/uivision/macros/PWP';

    my @file_array;
    opendir( my $dh, $location ) || die "Can't open $location: $!";
    while ( $file = readdir $dh ) {
        next if ( $file =~ /^\.+/ );
        chomp $file;
        next unless ( $file =~ /\.json$/ );
        push @file_array, $file;
        $file_cnt++;
        last if ( $file_cnt >= 9 );
    }
    closedir $dh;
    if ( ( scalar @file_array ) < 1 ) {
        print "no more files to be processed\n";
    }
    else {
        for my $file (@file_array) {
            my $mv_file = $location . $file;
            `cp $mv_file $ui_location; `;
        }
    }
}

sub help {

    my $help = <<"EOD";

Usage: ./prep_vine.pl options as follows:

-s single letter file json build ( must have -t option )
    example: ./prep_vine.pl -s -t AAA

-m multi-letter file json build ( must have -f and -t option )
    example: ./prep_vine.pl -m -f AAA -t ZZZ

-r multi-letter file json build ( must have -f and -t option )
    example: ./prep_vine.pl -r -f AAAA -t ZZZA
    Note: this is to produce a four letter search which will only produce
          the first three letters followed by a vowel

-f from letters ( must be less than -t )

-t to letters ( must be greater than -f )

note: -f and -t cannot be the same

-b build smove and rm bash scripts only

EOD
    print $help;
}
