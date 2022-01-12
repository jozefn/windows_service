package Vine;

use DBI;
use strict;
use Data::Dumper;


sub new {
    my $class = shift;
    my $args = shift;
    my $database =  $args->{database} || 'vine.db';
    my $do_rebuild = 0;
    if (! -e $database ){
        $do_rebuild =1
    }
    my $driver   = "SQLite";
    my $userid = "";
    my $password = "";
    my $self = {
        _driver => $driver,
        _userid => $userid,
        _password => $password,
    };
    bless $self, $class;

    $self->opendb({ "database" => $database });

    if ($do_rebuild){
        $self->rebuild_db($args);
    }

    return $self;
}

sub opendb{
    my $self = shift;
    my $args = shift;
    my $database = $args->{database};
    my $driver = $self->{_driver};
    my $dsn = "DBI:$driver:dbname=$database";
    my $password = $self->{_password};
    my $userid = $self->{_userrid};
    my $dbh = DBI->connect($dsn, $userid, $password, { RaiseError => 1 }) or die $DBI::errstr;
    $self->{dbh} = $dbh;
}

    

sub last_inserted_id{
    my $self = shift;
    my $id =  $self->{dbh}->sqlite_last_insert_rowid or die $DBI::errstr;
    return ($id);
}

sub do_sql{
    my $self = shift;
    my $args = shift;
    my $sql = $args->{sql};
    my $where = $args->{where} || 0;
    my $sth = $self->{dbh}->prepare( $sql );
    if ($where){
	    $sth->execute(@{$where}) or die $DBI::errstr;
    } else {
	    $sth->execute() or die $DBI::errstr;
    }
	return $sth;
}


sub rebuild_db{
    my $self = shift;
    my $args = shift;

    my $sql;
    my $start_found = 0;
    my $end_found = 0;

    my $sql_hash;
    my $start_key;

    while (<DATA>){
        chomp;
        if (/start_table\d/){
            $start_found = 1;
            $start_key = $_;
            $sql_hash->{$start_key} = "";
            next;
        }
        if (/end_table\d/){
            $start_found = 0;
            next;
        }
        if ($start_found){
            $sql_hash->{$start_key} .= "$_\n";
        }
    }

    foreach my $key ( sort keys %{$sql_hash} ){
        my $s = $sql_hash->{$key};
        my $sth = $self->do_sql({sql=> $s });
    }
}

1;



__DATA__

start_table0
DROP TABLE IF EXISTS "facility";
end_table0;

start_table1
CREATE TABLE IF NOT EXISTS "facility" (
	"id"	INTEGER NOT NULL UNIQUE,
	"name"	TEXT,
    "address" TEXT,
    "city" TEXT,
    "zip"  TEXT,
    "county" TEXT,
    "website" TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
end_table1

start_table2
DROP TABLE IF EXISTS "names";
end_table2

start_table3
CREATE TABLE IF NOT EXISTS "names" (
	"id"	INTEGER NOT NULL UNIQUE,
	"facility"	INTEGER,
	"name"	TEXT,
	"IID"	TEXT,
	"status"	TEXT,
    "cdate" TEXT,
    "mdate" TEXT,
	PRIMARY KEY("id" AUTOINCREMENT)
);
end_table3



