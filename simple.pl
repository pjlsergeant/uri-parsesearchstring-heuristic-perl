use strict;
use warnings;
use lib 'lib';

use URI::ParseSearchString::Heuristic;

my $obj = 'URI::ParseSearchString::Heuristic';

while (my $line = <STDIN>) {
	chomp($line);
	#print "*$line*\n";
	$obj->parse( $line );
}
