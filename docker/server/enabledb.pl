#!/usr/bin/perl

# Run this script to automatically comment/uncomment the
# database fields in nwnx2.ini. It will uncomment the mysql
# fields by default, but this can be specified with the -d
# argument, e.g. ./enabledb.pl -dpostgre

# It can most likely be optimized, but this was more of an
# educational perl exercise for myself than anything else.
# I tried to reduce the amount of probable side effects,
# but no promises! A backup of nwnx2.ini is written to
# nwnx2.ini.bak, but take care as this file will also be
# overwritten if run again.

use 5.010000;
use warnings;
use strict;
use Getopt::Std;

# parse arguments
my %args;
getopts('d:f:', \%args);
my $target_db = $args{d} || 'mysql';
my $filename = $args{f} || 'nwnx2.ini';

die "cannot open '$filename'!" unless -e $filename;

# scalars to hold parsing state
my $should_uncomment = 0;
my $reading_db_fields = 0;

# setup the inplace operation
# read <> from now on and
@ARGV = ($filename);
# keep backup at "$file.bak"
$^I = '.bak';

# seek out [ODBC2]
while (<>){
  print;
  last if(m/^\[ODBC2\]$/);
}
# proceed to (un)comment
while (<>){
  # stop when not not in [ODBC2] anymore
  if(m/^\[\w+\]$/) {
    print;
    last;
  }

  # consider empty line as end of db fields
  if (m/^\n$/) {
    $reading_db_fields = 0;
    print;
    next;
  }

  # decide if reading desired db fields
  if (m/^; for (\w+)$/) {
    $reading_db_fields = 1;
    if ($1 =~ $target_db) {
      $should_uncomment = 1;
    } else {
      $should_uncomment = 0;
    }
    print;
    next;
  }

  if ($reading_db_fields) {
    if ($should_uncomment) {
      s/^;//;
    } else {
      s/^(\w+)/;$1/;
    }
  }
  print;
}

while (<>){
  print;
}
