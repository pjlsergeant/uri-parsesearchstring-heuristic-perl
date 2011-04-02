#!perl
package URI::ParseSearchString::Heuristic::Configuration;

use strict;
use warnings;
use URI::Escape;

=head1 NAME

URI::ParseSearchString::Heuristic::Configuration - Configure the parser

=head1 SYNOPSIS

 use URI::ParseSearchString::Heuristic;
 use URI::ParseSearchString::Heuristic::Config;

 $URI::ParseSearchString::Heuristic::Config::key_presets->{'com.foobar'} =
 	{ engine_simple_name => 'Foo Bar Search' };

 my $parser = URI::ParseSearchString::Heuristic->new();
 # etc...

=head1 DESCRIPTION

All the lookup tables used by L<URI::ParseSearchString::Heuristic> are data
structures in this package. If you want to change them, you can access and
modify them from within your application, as shown in the Synopsis. The rest
of this documentation will explain what's available and how it's used.

=head1 IMPLEMENTATION DETAILS

Bla bla bla

=head2 export_vars

Returns a hash of the configuration values

=cut

our @export_arrays = (qw( forbidden_strings stop_words ));
our @export_hashes = (qw(
	families family_specifics non_heuristic_keys key_scores
	simple_maps all_caps key_presets family_presets
));
sub export_vars {
	my $class = shift;
	my %symbols = ();

	no strict 'refs';
	$symbols{ $_ } = \%{ $class . '::' . $_ } for @export_hashes;
	$symbols{ $_ } = \@{ $class . '::' . $_ } for @export_arrays;

	return %symbols;
}

=head1 AVAILABLE CONFIGS

=head2 %families

 $URI::ParseSearchString::Heuristic::Configuration::families{'google'} = 1;

Defines a search engine as being part of a family of search engines. This means
we may attempt to add geographic information to its C<engine_full_name>, means
you can specify subdomains (like photos or blogs) and we'll set the
C<engine_family> and C<engine_family_key> parameters.

The keyname is the most significant part of the domain, and the value should
be set to true.

=cut

# Search engine families
our %families = map { $_ => 1 }
    qw( google yahoo lycos aol excite msn altavista ask sapo tiscali );

=head2 %family_specifics

 $URI::ParseSearchString::Heuristic::Configuration::family_specifics{'google'} =
 	[qw( blogsearch images books groups groups-beta local )];

Defines a subdomain of a family of search engines to be note-worthy.

=cut

our %family_specifics = (
    'google'  => [qw( blogsearch images books groups groups-beta local )],
    'sapo'    => [qw( fotos videos sabores )],
    'yahoo'   => [qw( education google )],
);

# Keys known to give us problems...
our %non_heuristic_keys = map { $_ => 1 }
    qw(next col btnG submit rfr WILDCARD METAENGINE replayhash group pageName
    alias googletbms );

my $preference_counter = 0;
our %key_scores = map { $_ => ++$preference_counter } reverse (
        'query',              # CNET Search, Netscape
        'search', 'Search', 'searchfor',
        'term', 'terms',      # abcsearch.com
        'ask',                # Ask Jeeves
        'palabras',
        'DTqb1',
        'request',
        'ShowMatch',          # syndic8
        'keyword', 'keywords', 'Keywords', # Snap, overture.com, Earthnet
        'general',            # MetaCrawler, Go2Net
        'key',                # Looksmart
        'MetaTopic',          # AJ
        'query0',             # elf8888.at, thx to http://www.tnl.net/
        'queryString',        # blogdigger.com
        'serachfor',          # mysearch.com dyslexia ;)
        'word','wd',          # baidu.com
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

our @forbidden_strings = ( 'ikonboard.cgi', 'ultimatebb.cgi' );

our @stop_words = (
    qr/^www\d*$/o,
    qr/^search$/o,
    qr/^busca(dor|r)?%/o,
);

our %simple_maps = (
    'yahoo' => 'Yahoo!',
    'blogseach' => 'Blog Search',
);
our %all_caps = map { $_ => 1 } qw( aol msn xl sapo icq );

our %key_presets = (
    'pt.record'         => { engine_simple_name => 'Jornal Record' },
    'com.rr'            => { engine_simple_name => 'Road Runner'   },
    'net.att'           => { engine_simple_name => 'AT&T'          },
    'com.search'        => { engine_simple_name => 'Search.com'    },
    'net.earthlink-help'=> { engine_simple_name => 'myEarthLink'   },
    'com.howstuffworks' => { engine_simple_name => 'HowStuffWorks' },
	'com.need2find'     => { engine_simple_name => 'Need2Find'     },
    'com.yahoo.google'  => { engine_simple_name => 'Yahoo!', engine_full_name => 'Yahoo! (via Google)' },
	'com.google.groups-beta' => { engine_simple_name => 'Google Groups' },
    'com.baidu'         => { search_terms_encoding => 'euc-cn'     },
);

our %family_presets = (
	'google.images' => {
		search_param => 'prev',
		search_transform => sub {
			my ( $data, $terms ) = @_;
			$terms =~ s!^/images\?q=!!;
			uri_unescape( $terms );
		}
	}
);

our %google_tbms = (
	blg => 'blogsearch'
);

1;