#!perl
package URI::ParseSearchString::Heuristic;

use strict;
use warnings;
use URI::ParseSearchString::Heuristic::TLD;
use URI::ParseSearchString::Heuristic::URI;

# Search engine families
our %families = map { $_ => 1 }
    qw( google yahoo lycos aol excite msn altavista ask sapo );

sub _transfer_atom {
    my ( $self, $from, $to ) = @_;
    return unless @$from;

    my $item = shift(@$from);
    $to->{'engine_key'} =
        $to->{'engine_key'} ? $to->{'engine_key'} . '.' . $item : $item;
    return $item;
}

our %more_specific = (
    'google'  => ['blogsearch', 'images'],
    'sapo'    => ['fotos', 'videos', 'sabores'],
);

our $uri_parser = 'URI::ParseSearchString::Heuristic::URI';

sub parse {
    my ( $self, $url ) = @_;

    # Sanity check 1
    return if index( $url, 'http' );  # Return unless the string starts with http

    # Parse the URL in to parts
    my $result = $uri_parser->parse( $url );
    return unless $result;

    my ( $hostname, $atoms, $path_query, $params, $param_string ) = @$result;

    # Pass the atoms in
    my $data = $self->parse_host( $atoms, $hostname );
    $data->{'url'} = $url;

    my $search = $self->parse_query( $data, $params, $param_string );
    $data->{'search_terms'} = $search;

    use Data::Dumper;
    print Dumper $data;
}

my %cache;

sub set_cached_engine {
    my ( $self, $host, $data ) = @_;
    my %copy = %$data;
    $cache{ $host } = \%copy;
    return \%copy;
}

sub get_cached_engine {
    my ( $self, $host ) = @_;
    if ( $cache{ $host } ) {
        return { %{ $cache{$host} } };
    } else {
        return;
    }
}

# Keys known to give us problems...
our %non_heuristic_keys = map { $_ => 1 } qw(next col btnG submit rfr WILDCARD METAENGINE);
my $preference_counter = 0;
our %key_scores = map { $_ => ++$preference_counter } reverse (
        'query',              # CNET Search, Netscape
        'search',
        'term', 'terms',      # abcsearch.com
        'ask',                # Ask Jeeves
        'palabras',
        'DTqb1',
        'request',
        'ShowMatch',          # syndic8
        'keyword', 'keywords', # Snap, overture.com
        'general',            # MetaCrawler, Go2Net
        'key',                # Looksmart
        'MetaTopic',          # AJ
        'query0',             # elf8888.at, thx to http://www.tnl.net/
        'queryString',        # blogdigger.com
        'serachfor',          # mysearch.com dyslexia ;)
        'word',               # baidu.com
        'rn',
        'mt',                 # MSN, HotBot
        'qt',                 # Go, Infoseek, search.com
        'oq',
        'dom',                # Domainsurfer
        'q',                  # Altavista, Google, Dogpile, Evreka, Metafind
        's',                  # Excite, blogsphere.us
        'p',                  # Yahoo
        't',
        'qry',
        'qkw',                # dpxml, msxml
        'qr',                 # northernlight.com
        'qu',
        'kw',                 # Sapo
        'general',
        'B1',
        'sc',                 # Gohip
        'szukaj',
        'PA',
        'MT',                 # goo.ne.jp
        'req',                # dir.com
        'k',                  # galaxy.com
        'cat',                # Dmoz
        'va',                 # search.yahoo.com
        'K',                  # srd.yahoo.com
        'as_epq',             # Google, sometimes. Advanced query maybe?
        'kp'                  # Fact bites
    );

sub parse_query {
    my ( $self, $engine_data, $params, $param_string ) = @_;
    return unless keys %$params;

    # If we know it, go with that
    if ( $engine_data->{'search_param'} ) {
        $engine_data->{'search_param_from'} = 'preset';
        return $params->{ $engine_data->{'search_param'} };
    }

    # Flatten the parameters and sort by preference
    my @param_array =
        sort { $b->[2] <=> $a->[2] }
        map  { [ $_ => $params->{$_}, ($key_scores{$_}||0) ] }
        grep {! $non_heuristic_keys{$_} }
        keys %$params;
    return unless @param_array;

    # Are we using the search heuristic?
    if ( index( $param_string, '+' ) > 0 || index( $param_string, '%20' ) > 0 ) {
        my ( $result ) = grep { $_->[1] =~ m/ /} @param_array;
        if ( $result ) {
            $engine_data->{'search_param_from'} = 'heuristic_space';
            return $result->[1];
        }
    }

    # That didn't work. Do we match any keys?
    my ( $result ) = grep { $_->[2] } @param_array;
    if ( $result ) {
        $engine_data->{'search_param'}      = $result->[0];
        $engine_data->{'search_param_from'} = 'heuristic_param';
        return $result->[1];
    }

    return undef;
}

# Turns a series of hostname atoms an identifier and related data
sub parse_host {
    my ( $self, $atoms_incoming, $full_host ) = @_;
    $full_host ||= join '.', reverse @$atoms_incoming;

    # Use the cached version if we have one
    my $cached = $self->get_cached_engine( $full_host );
    return $cached if $cached;

    # This is where we'll build the search-engine data
    my $data = {};

    # Special-handle IP addresses
    unless ( $full_host =~ m/[a-z]/ ) {
        $data->{'engine_simple_name'} = 'IP: ' . $full_host;
        $data->{'engine_key'} = $full_host;
        goto CLEANUP;
    }

    # Take a copy of them now. Every significant part we'll move to atoms_used
    # which will be used to form our identifier
    my @atoms = @$atoms_incoming;

    # Get the root atom
    my $tld = $self->_transfer_atom( \@atoms, $data );

    # Was it a single-atom host? If so, then it was almost certainly local
    {
        no warnings 'deprecated';
        goto LOCALDOMAIN unless @atoms;
    }

    # If it ends with a recognized non-geographic TLD then we use the next
    # domain atom, with the first letter uppercased.
    if ( $URI::ParseSearchString::Heuristic::TLD::international{ $tld } ) {

        # Get the 'name' part
        my $name = $self->_transfer_atom( \@atoms, $data );
        $data->{'engine_simple_name'} = $self->stylize_name($name);

        # Add a country if it's a big international and we can find it in the
        # atoms. First let's just check it's an international...
        if ( $families{ $name } ) {
            $data->{'engine_family'} = $name;

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
            }
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
        if ( $families{ $name } ) {
            $data->{'engine_full_name'} = $self->stylize_name( $name ) . ' ' . $country;
            $data->{'engine_family'} = $name;
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
    while ( my $specifics = $more_specific{ $data->{'engine_family'} } ) {
        last unless @atoms;
        last unless grep { $atoms[0] eq $_ } @$specifics;

        my $name = $self->_transfer_atom( \@atoms, $data );
        $data->{'engine_simple_name'} .= ' ' . $self->stylize_name( $name );
        if ( $data->{'engine_full_name'} ) {
            $data->{'engine_full_name'} .= ' ' . $self->stylize_name( $name );
        }
    }

    CLEANUP:
    # Fold in any presets
    %$data = (%$data, $self->engine_presets( $data->{'engine_key'} ));

    # Default the full name to the simple one if it hasn't been set yet
    $data->{'engine_full_name'} ||= $data->{'engine_simple_name'};

    $self->set_cached_engine( $full_host, $data );
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
    'com.rr'            => { engine_simple_name => 'Road Runner'   },
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