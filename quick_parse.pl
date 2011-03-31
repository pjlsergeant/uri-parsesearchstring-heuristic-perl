#!perl

use strict;
use warnings;

use URI;
use URI::Escape;
use Test::More;

no warnings 'uninitialized';

for my $test (
	'http://2001::123:4567:abcd:8080/something?la',
	'http://administrator:password@64.105.135.30/original?s',
	'http://foo/bar#?asdf',
	'https://some-url.com?query=&name=joe?filter=*.*#some_anchor',
	'http://userid:password@example.com:8080/?foo',
	'http://%77%77%77%2e%70%65%72%6c%2e%63%6f%6d/%70%75%62/%61/%32%30%30%31/%30%38/%32%37/%62%6a%6f%72%6e%73%74%61%64%2e%68%74%6d%6c?asdf',
	'https://www.perl.com/path?foo=bar&bar=baz',
) {
	diag( $test );
	my ( $ret_host, $ret_query ) = parse_url_quick( $test );
	my $uri = URI->new( $test );

	if ( $uri && eval { $uri->query } ) {
		is( $ret_host,  $uri->host,  "Hostname matched: $ret_host" );
		is( $ret_query, $uri->query, "Query passes: $ret_query"    );
	} else {
		is( $ret_host, undef, "$test has an undefined host" );
		is( $ret_query, undef, "$test has an undefined query" );
	}
}


sub parse_url_quick {
	my $url = shift;
	my $url_copy = $url;
	return unless $url_copy =~ s!^https?://(?:[^/?]+\@)?([^/?]+)[^\?\#]*\?([^\#]+)!!;
	my ( $authority, $query ) = ( $1, $2 );
	$authority =~ s/\:(\d+)$//;

	return ( uri_unescape($authority), $query );
}
