#!perl

use strict;
use warnings;

use Test::More;
use YAML::Syck;
use URI::ParseSearchString::Heuristic;

my $obj = 'URI::ParseSearchString::Heuristic';
my $data = LoadFile('corpus_clean.yaml');
my $fails;

for my $test (@$data) {
	my $url = delete( $test->{'url'} );
	print $url . "\n";
	note $url;

	my $result = $obj->parse( $url ) || {};

	for (
		['engine_simple_name', 'name'],
		['engine_full_name', 'full_name'],
		['search_terms', 'terms'],
	) {
		my $expected = $test->{ $_->[1] } || '';
		my $returned = $result->{ $_->[0] } || '';
        utf8::encode($returned);

		is( $returned, $expected, $_->[0] . ' match: ' . $expected ) || $fails++;
	}

	if ($fails) {
		$fails = $result;
		last;
	}
}

use Data::Dumper;
if ( $fails ) {
	diag Dumper $fails;
}

done_testing;
