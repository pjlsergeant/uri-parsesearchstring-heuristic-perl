package URI::ParseSearchString::Heuristic::URI;

use strict;
use warnings;

use URI;
use URI::QueryParam;

# Accept a data object and expand it out based on the URL.
# Input:
#   meta_url_full
# Output:
#   meta_url_atoms
#   meta_url_hostname
#   meta_url_path
#   meta_url_query
#   params

# This is currently slow. I have a plan for making it FAST.
sub parse {
	my ($self, $data) = @_;
	return unless $data->{'meta_url_full'};

	# Initial parse
	my $uri_object = URI->new( $data->{'meta_url_full'}, 'http' );
	return unless $uri_object;
	return unless $uri_object->isa('URI::http');

	# Set what we have
	$data->{'meta_url_hostname'} = $uri_object->host  || return;
	$data->{'meta_url_path'}     = $uri_object->path;
	$data->{'meta_url_query'}    = $uri_object->query || return;

	# IP address?
	$data->{'meta_url_is_ip'} =
		# IPv6
		( $data->{'meta_url_hostname'} =~ m/\:/ ) ||
		# IPv4
		( $data->{'meta_url_hostname'} =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) ||
		0;

	# Split out the hostname
	if (! $data->{'meta_url_is_ip'} ) {
		$data->{'meta_url_atoms'} =
			[reverse split(/\./, $data->{'meta_url_hostname'} )];
	} else {
		$data->{'meta_url_atoms'} = [$data->{'meta_url_hostname'}];
	}

	# Parse the query string
	$data->{'params'} = $uri_object->query_form_hash;
	return 1 if values %{ $data->{'params'} };
}

1;