#!perl
use strict;
use warnings;

use URI::ParseSearchString::Heuristic;
use Data::Dumper;

while (my $host = <STDIN>) {
	chomp($host);
print Dumper (URI::ParseSearchString::Heuristic->parse_host( $host )); 
}
