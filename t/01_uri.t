#!perl

use strict;
use warnings;
use Test::More tests => 11;

use_ok('URI::ParseSearchString::Heuristic::URI');

for (
	['http://au.altavista.com/q?q=quake+2+servers&what=web&kl=XX&stq=10&nbq=10',
		'au.altavista.com',
		'/q?q=quake+2+servers&what=web&kl=XX&stq=10&nbq=10',
		{ 'q' => 'quake 2 servers', what => 'web', kl => 'XX', stq => '10', nbq => '10' }
	],
	['http://www.wired.com',
		'www.wired.com',
		'',
		{}
	],
	['http://foobar/My+Search',
		'foobar',
		'/My+Search',
		{}
	]
) {
	my ( $ref_uri, $ref_host, $ref_path, $ref_params ) = @$_;
	my ( $test_host, $test_path, $test_params ) =
		@{ URI::ParseSearchString::Heuristic::URI::parse( $ref_uri ) };

	is( $test_host, $ref_host, "$ref_uri - Host correctly matched" );
	is( $test_path, $ref_path, "$ref_uri - Path correctly matched" );
	is_deeply( $test_params, $ref_params, "$ref_uri - Params matched" );
}

is(
	URI::ParseSearchString::Heuristic::URI::parse( 'zoombaromba!' ),
	undef,
	"Undef on silly URIs"
);