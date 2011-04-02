package URI::ParseSearchString::Heuristic::URI;

use strict;
use warnings;

use URI;
use URI::QueryParam;

# Take a URI, return an array ref of the hostname, path-query, and a hashref
# of parameters. One day I hope to make this really fast...
sub parse {
	my ($self, $uri) = @_;

	# Initial parse
	my $uri_object = URI->new( $uri, 'http' );

	return unless $uri_object;
	return unless $uri_object->isa('URI::http');
	return unless $uri_object->host;

    my $data = $uri_object->query_form_hash;
    return unless values %$data;

    # We're going to make the judgement call here that multi-params are not the
    # search params
    for my $key (keys %$data) {
        delete $data->{$key} if ref $data->{$key};
    }

	my $result = [
		$uri_object->host,
		[ reverse split(/\./, $uri_object->host) ],
		$uri_object->path,
		$data,
		$uri_object->query
	];

	return $result;
}

1;