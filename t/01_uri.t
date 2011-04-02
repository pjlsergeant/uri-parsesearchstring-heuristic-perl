#!perl

use strict;
use warnings;
use Test::More;

use_ok( 'URI::ParseSearchString::Heuristic::URI' );

for (
	[
		'https://www.google.com/baz?foo=bar', 1,
		{
			meta_url_atoms    => ['com','google','www'],
			meta_url_hostname => 'www.google.com',
			meta_url_path     => '/baz',
			meta_url_query    => 'foo=bar',
			meta_url_is_ip    => 0,
			params            => {
				foo => 'bar'
			}
		}
	], [
		'http://au.altavista.com/q?q=quake+2+servers&what=web&kl=XX&stq=10', 1,
		{
			meta_url_atoms    => ['com','altavista','au'],
			meta_url_hostname => 'au.altavista.com',
			meta_url_path     => '/q',
			meta_url_query    => 'q=quake+2+servers&what=web&kl=XX&stq=10',
			meta_url_is_ip    => 0,
			params            => {
				'q'    => 'quake 2 servers',
				'what' => 'web',
				'kl'   => 'XX',
				'stq'  => '10',
			}
		}
	], [
		'www.wired.com', 0, {}
	], [
		'http://www.wired.com', 0,
		{
			meta_url_hostname => 'www.wired.com',
			meta_url_path     => '',
		}
	], [
		'http://209.85.129.104/search?q=hi', 1, {
			meta_url_atoms    => [ '209.85.129.104' ],
			meta_url_hostname => '209.85.129.104' ,
			meta_url_path     => '/search',
			meta_url_query    => 'q=hi',
			meta_url_is_ip    => 1,
			params            => {
				'q' => 'hi'
			}
		}
	], [
		'http://[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]:80/search?q=hi', 1, {
			meta_url_atoms    => [ '[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]' ],
			meta_url_hostname => '[FEDC:BA98:7654:3210:FEDC:BA98:7654:3210]',
			meta_url_path     => '/search',
			meta_url_query    => 'q=hi',
			meta_url_is_ip    => 1,
			params            => {
				'q' => 'hi'
			}
		}
	]
) {
	my ( $url, $bool, $expected ) = @$_;
	$expected->{'meta_url_full'} = $url;
	note $url;

	my $data = { meta_url_full => $url };
	my $result = URI::ParseSearchString::Heuristic::URI->parse( $data ) || 0;
	is( $result, $bool, "parse() returned $bool" );
	is_deeply( $data, $expected, "Parts as expected" );
}

done_testing();