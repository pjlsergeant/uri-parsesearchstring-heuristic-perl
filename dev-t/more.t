# -*- perl -*-

use strict;
use warnings;

use Test::More qw( no_plan );
use Data::Dumper;
use URI::ParseSearchString::Heuristic;

use lib '../lib';

use Config::General;
my $conf = new Config::General(
	-ConfigFile => $ARGV[0],
	-BackslashEscape => 1,
);
my %config = $conf->getall;

foreach my $test ( @{$config{'urls'}}) {

	my ( $url, $ref_terms ) = ( $test->{'url'}, $test->{'terms'} );
	$url = 'http://' . $url if index($url,'http');

	my $returned = URI::ParseSearchString::Heuristic->parse( $url );
	my $terms = $returned ? $returned->{'search_terms'} : '';

	is( $terms, $ref_terms, "$url [$terms]" );
 }
