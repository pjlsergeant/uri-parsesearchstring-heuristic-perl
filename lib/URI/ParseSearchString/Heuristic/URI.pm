package URI::ParseSearchString::Heuristic::URI;

use strict;
use warnings;

use URI;
use URI::QueryParam;

# Take a URI, return an array ref of the hostname, path-query, and a hashref
# of parameters. One day I hope to make this really fast...
sub parse {
	my $uri = shift;

	# Initial parse
	my $uri_object = URI->new( $uri, 'http' );
	return unless $uri_object;
	return unless $uri_object->isa('URI::http');
	return unless $uri_object->host;

	my $result = [
		$uri_object->host,
		$uri_object->path_query,
		$uri_object->query_form_hash
	];

	return $result;
}

1;