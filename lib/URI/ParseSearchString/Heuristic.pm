#!perl
package URI::ParseSearchString::Heuristic;

use strict;
use warnings;

sub new {
	my ( $class, %options ) = @_;

	my $self = {
		uri_parser	 => 'URI::ParseSearchString::Heuristic::URI',
		config_package => 'URI::ParseSearchString::Heuristic::Config',
		return_meta	=> 1,
		%options
	};

	bless $self, $class;

	# Pull in the external config
	eval "require " . $self->{'config_package'};
	die $@ if $@;
	my %symbols = $self->{'config_package'}->export_vars();
	$self->{':' . $_} = $symbols{$_} for keys %symbols;

	return $self;
}

sub parse {
	my ( $self, $url ) = @_;

	# Create the message that we'll be putting through the pipeline
	my $data = { url_full => $url };

	# Splice and dice the URL
	GOTO cleanup unless $self->{'uri_parser'}->parse( $url, $data );

	# Parse the hostname
	unless ( $self->_get_host_cache( $data ) ) {
		$self->_parse_host(     $data );
		$self->_get_presets(    $data );
		$self->_set_host_cache( $data );
	}

	# Parse the search terms themselves
	GOTO cleanup unless $self->_parse_terms( $data );

	# Gussy up the name
	GOTO cleanup unless $self->_prepare_name( $data );

	# Cleanup phase
cleanup:
	# Check for a failed parse
	if (! $data->{'search_terms'} ) {
		# Have we been asked to return our partial-parses?
		if ( $self->{'return_meta'} ) {
			return $data;
		# If not, return undef
		} else {
			return;
		}
	}
}

sub _get_presets {
# Input:
#   meta_url_key
#   engine_type
#   meta_family
# Output:
#   meta_param
#   meta_param_heuristic
#   meta_encoding

	my ( $self, $data ) = @_;
	# Look for presets based on family and type

}

sub _parse_host {
	my ( $self, $data ) = @_;
# Input:
#   meta_url_full
#   meta_url_atoms
#   meta_url_hostname
#   meta_url_is_ip
# Output:
#   engine_name
#   engine_type <- maybe
#   engine_location
#   meta_family
#   meta_url_key
#   meta_url_is_local

	# If it's an IP, there's very little we can do
	if ( $data->{'meta_url_is_ip'} ) {
		$data->{'engine_name'}  = $data->{'meta_url_hostname'};
		$data->{'meta_url_key'} = 'ip:' . $data->{'meta_url_hostname'};
		return 1;
	}

	# Take a copy of the incoming host atoms
	my @atoms = @{$data->{'meta_url_atoms'}};

	# Get the root atom
	my $tld = $self->_transfer_atom( \@atoms, $data );

	# Was it a single-atom host? If so, then it was almost certainly local
	{
		no warnings 'deprecated';
		goto LOCALDOMAIN unless @atoms;
	}

	# If it ends with a recognized non-geographic TLD then we use the next
	# domain atom, with the first letter uppercased.
	if ( $self->{':tld_international'}->{ $tld } ) {

		# Get the 'name' part
		my $name = $self->_transfer_atom( \@atoms, $data );
		$data->{'engine_name'} = $name;

		# Is it part of a family?
		if ( $self->{':families'}->{$name} ) {
			$data->{'meta_family'} = $name;

			# See if we can find a geoloc in the rest of the atoms. Do a scan
			# first
			if ( grep { $_ } map { $self->{':tld_geographic'}->{ $_ } } @atoms ) {
				while ( @atoms ) {
					my $potential = $self->_transfer_atom( \@atoms, $data );
					if ( $self->{':tld_geographic'}->{ $potential } ) {
						$data->{'engine_location'} = $potential;
						last;
					}
				}
			}
		}

	# If it ends with a geographic TLD...
	} elsif ( $self->{':tld_geographic'}->{ $tld } ) {

		# First set the country
		$data->{'engine_location'} = $tld;

		# Does the next segment look legit? This condition returns true if it's
		# NOT legit.
		if (
			# Assume it's legit if it's the only part remaining
			( scalar(@atoms) > 1 ) && (
				# Well-known second-level domain
				( $self->{':tld_second_level'}->{ $atoms[0] } ) ||
				# You're awfully short...
				( length( $atoms[0] ) < 3 )
			)
		) {
			# So the next part of the URL didn't look like it'd be the name.
			# Let's take it off the stack
			$self->_transfer_atom( \@atoms, $data ) unless
				# Unless the next part is a stop-word
				($atoms[1] && $self->_is_stop_word($atoms[1]));
		}

		# At the name!
		my $name = $self->_transfer_atom( \@atoms, $data );
		$data->{'engine_name'} = $name;
		$data->{'meta_family'} = $name if $self->{':families'}->{$name};

	# Local domains!
	} else {
	LOCALDOMAIN:
		$data->{'meta_url_is_local'} = 1;

		if ( $tld eq 'local' && @atoms ) {
			$data->{'engine_name'} = $self->_transfer_atom( \@atoms, $data );
		} else {
			$data->{'engine_name'} = $tld;
		}
	}

	# Search for clues as to the type of thing we were searching for
	if ( $data->{'meta_family'} && @atoms ) {
		# Do any atoms remaining match a specific?
		 my ($match) = grep {
				my ( $part, $type ) = @$_;
				grep { $_ eq $part } @atoms;
			} @{ $self->{':family_specifics'}->{ $data->{'meta_family'} } };
		if ($match) {
			my ( $part, $etype ) = @$match;
			$data->{'engine_type'} = $etype;

			# Remove atoms until we find the right one...
			while ( my $atom = $self->_transfer_atom( \@atoms, $data ) ) {
				last if $atom eq $part;
			}
		}
	}

	return 1;
}

sub _is_stop_word {
    my ( $self, $atom ) = @_;
    my $count = grep { $atom =~ $_ } @{ $self->{':stop_words'} };
    return !!$count;
}

sub _transfer_atom {
	my ( $self, $from, $to ) = @_;
	return unless @$from;

	my $item = shift(@$from);
	$to->{'meta_url_key'} =
		$to->{'meta_url_key'} ? $to->{'meta_url_key'} . '.' . $item : $item;
	return $item;
}

1;