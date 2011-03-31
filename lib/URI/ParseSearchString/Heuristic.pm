#!perl
package URI::ParseSearchString::Heuristic;

use strict;
use warnings;
use URI::ParseSearchString::Heuristic::TLD;

# Search engines that probably need a country designation
our %international = map { $_ => 1 }
	qw( google yahoo lycos aol excite msn altavista ask);

sub _transfer_atom {
	my ( $self, $from, $to ) = @_;
	return unless @$from;

	my $item = shift(@$from);
	$to->{'engine_key'} =
		$to->{'engine_key'} ? $to->{'engine_key'} . '.' . $item : $item;
	return $item;
}

our %more_specific = (
	'com.google' => ['blogsearch'],
	'pt.sapo'    => ['fotos', 'videos', 'sabores'],
);

# Turns a series of hostname atoms an identifier and related data
sub parse_host {
	my ( $self, $atoms_incoming ) = @_;

	# Take a copy of them now. Every significant part we'll move to atoms_used
	# which will be used to form our identifier
	my @atoms = @$atoms_incoming;

	# This is where we'll build the search-engine data
	my $data = {};

	# Get the root atom
	my $tld = $self->_transfer_atom( \@atoms, $data );

	# Was it a single-atom host? If so, then it was almost certainly local
	goto LOCALDOMAIN unless @atoms;

	# If it ends with a recognized non-geographic TLD then we use the next
	# domain atom, with the first letter uppercased.
	if ( $URI::ParseSearchString::Heuristic::TLD::international{ $tld } ) {

		# Get the 'name' part
		my $name = $self->_transfer_atom( \@atoms, $data );
		$data->{'engine_simple_name'} = $self->stylize_name($name);

		# Add a country if it's a big international and we can find it in the
		# atoms. First let's just check it's an international...
		if ( $international{ $name } ) {
			# Do a quick first-pass to see if it's worth continuing
			if ( grep {$_} map {
				$URI::ParseSearchString::Heuristic::TLD::geographic{$_} }
				@atoms
			) {
				# It is, so go through the atoms one by one until we find the
				# geographic one
				my $country;
				while ( @atoms ) {
					my $potential =
						$self->_transfer_atom( \@atoms, $data );
					last if $country =
						$URI::ParseSearchString::Heuristic::TLD::geographic{$potential};
				}

				# Make the name geographic
				$data->{'engine_full_name'} =
					$data->{'engine_simple_name'} .
					' ' . $country;
				$data->{'engine_country'} = $country;

			# No geographic marker found
			} else {
				$data->{'engine_full_name'} = $data->{'engine_simple_name'};
			}

		# Not an international, so not even looking
		} else {
			$data->{'engine_simple_name'};
		}

	# If it ends with a geographic TLD...
	} elsif (my $country = $URI::ParseSearchString::Heuristic::TLD::geographic{ $tld } ) {

		# First set the country
		$data->{'engine_country'} = $country;

		# Does the next segment look legit? This condition returns true if it's
		# NOT legit.
		if (
			# Assume it's legit if it's the only part remaining
			( scalar(@atoms) > 1 ) && (
				# Well-known second-level domain
				( $URI::ParseSearchString::Heuristic::TLD::second_level{ $atoms[0] } ) ||
				# You're awfully short...
				( length( $atoms[0] ) < 3 )
			)
		) {
			# It's relevant as used, but get it off the stack so we can look for
			# a naming atom
			$self->_transfer_atom( \@atoms, $data ) unless
				# Unless the next part is a stop-word
				($atoms[1] && $self->is_stop_word($atoms[1]));
		}

		my $name = $self->_transfer_atom( \@atoms, $data );
		$data->{'engine_simple_name'} = $self->stylize_name( $name );
		if ( $international{ $name } ) {
			$data->{'engine_full_name'} = $self->stylize_name( $name ) . ' ' . $country;
		}

	# Local domains!
	} else {
	LOCALDOMAIN:
		if ( $tld eq 'local' ) {
			if ( @atoms ) {
				my $name = $self->_transfer_atom( \@atoms, $data );
				$data->{'engine_simple_name'} = $self->stylize_name( $name );
			}
		} else {
			$data->{'engine_simple_name'} = $tld;
		}
	}

	# Add specifics as relevant
	while ( my $specifics = $more_specific{ $data->{'engine_key'} } ) {
		last unless @atoms;
		last unless grep { $atoms[0] eq $_ } @$specifics;

		my $name = $self->_transfer_atom( \@atoms, $data );
		$data->{'engine_simple_name'} .= ' ' . $self->stylize_name( $name );
		if ( $data->{'engine_full_name'} ) {
			$data->{'engine_full_name'} .= ' ' . $self->stylize_name( $name );
		}
	}

	# Fold in any presets
	%$data = (%$data, $self->engine_presets( $data->{'engine_key'} ));

	# Default the full name to the simple one if it hasn't been set yet
	$data->{'engine_full_name'} ||= $data->{'engine_simple_name'};

	return $data;
}

our @stop_words = (
	qr/^www\d*$/o,
	qr/^search$/o,
	qr/^busca(dor|r)?%/o,
);
sub is_stop_word {
	my ( $self, $atom ) = @_;
	my $count = grep { $atom =~ $_ } @stop_words;
	return !!$count;
}

our %all_caps = map { $_ => 1 } qw( aol msn xl sapo );
sub stylize_name {
	my ($self, $name) = @_;
	return 'Yahoo!' if $name eq 'yahoo';
	return 'Blog Search' if $name eq 'blogsearch';
	return uc($name) if $all_caps{$name};
	return ucfirst( $name );
}

our %presets = (
	'pt.record'         => { engine_simple_name => 'Jornal Record' },
);
sub engine_presets {
	my ( $self, $key ) = @_;
	return $presets{$key} ? ( %{ $presets{ $key } } ) : ();
}

1;

__DATA__
search_terms
engine_simple_name
engine_full_name
engine_country
engine_url
engine_key