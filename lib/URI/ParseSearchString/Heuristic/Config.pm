#!perl
package URI::ParseSearchString::Heuristic::Config;

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
	tld_local tld_international tld_second_level tld_geographic
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
    'google'  => [
    	[ blogsearch    => 'blog'  ],
    	[ images        => 'image' ],
    	[ books         => 'book'  ],
    	[ groups        => 'group' ],
    	[ 'groups-beta' => 'group' ],
    	[ 'local'       => 'geographic' ],
    ],
    'sapo'    => [
    	[ fotos   => 'image' ],
    	[ videos  => 'video' ],
    	[ sabores => 'food'  ],
    ],
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

our %tld_second_level = map { $_ => 1 }
	qw( gov mil com net org host );

our %tld_international = map { $_ => 1 }
	qw(info aero asia arpa biz cat coop jobs mobi museum name pro travel tel
	com net org gov mil edu int);

our %tld_local = ( 'local' => 1 );

our %tld_geographic = (
		asia => 'Asia',
		ac => q{Ascension Island},
		ad => q{Andorra},
		ae => q{UAE},
		af => q{Afghanistan},
		ag => q{Antigua and Barbuda},
		ai => q{Anguilla},
		al => q{Albania},
		am => q{Armenia},
		an => q{Netherlands Antilles},
		ao => q{Angola},
		aq => q{Antartica},
		ar => q{Argentina},
		as => q{American Samoa},
		at => q{Austria},
		au => q{Australia},
		aw => q{Aruba},
		ax => q(Aland Islands),
		az => q{Azerbaijan},
		ba => q{Bosnia and Herzegovina},
		bb => q{Barbados},
		bd => q{Bangladesh},
		be => q{Belgium},
		bf => q{Burkina Faso},
		bg => q{Bulgaria},
		bh => q{Bahrain},
		bi => q{Burundi},
		bj => q{Benin},
		bl => q(St. Barthelemy),
		bm => q{Bermuda},
		bn => q{Brunei Darussalam},
		bo => q{Bolivia},
		br => q{Brazil},
		bs => q{Bahamas},
		bt => q{Bhutan},
		bv => q{Bouvet Island},
		bw => q{Botswana},
		by => q{Belarus},
		bz => q{Belize},
		ca => q{Canada},
		cc => q{Cocos Islands},
		cd => q{Congo},
		cf => q{Central African Republic},
		cg => q{Congo, Republic of},
		ch => q{Switzerland},
		ci => q{Cote d'Ivoire},
		ck => q{Cook Islands},
		cl => q{Chile},
		cm => q{Cameroon},
		cn => q{China},
		co => q{Colombia},
		cr => q{Costa Rica},
		cu => q{Cuba},
		cv => q{Cap Verde},
		cx => q{Christmas Island},
		cy => q{Cyprus},
		cz => q{Czech Republic},
		de => q{Germany},
		dj => q{Djibouti},
		dk => q{Denmark},
		dm => q{Dominica},
		do => q{Dominican Republic},
		dz => q{Algeria},
		ec => q{Ecuador},
		ee => q{Estonia},
		eg => q{Egypt},
		eh => q{Western Sahara},
		er => q{Eritrea},
		es => q{Spain},
		et => q{Ethiopia},
		eu => q{European Union},
		fi => q{Finland},
		fj => q{Fiji},
		fk => q{Falkland Islands},
		fm => q{Micronesia},
		fo => q{Faroe Islands},
		fr => q{France},
		ga => q{Gabon},
		gb => q{United Kingdom},
		gd => q{Grenada},
		ge => q{Georgia},
		gf => q{French Guiana},
		gg => q{Guernsey},
		gh => q{Ghana},
		gi => q{Gibraltar},
		gl => q{Greenland},
		gm => q{Gambia},
		gn => q{Guinea},
		gp => q{Guadeloupe},
		gq => q{Equatorial Guinea},
		gr => q{Greece},
		gs => q{South Georgia and the South Sandwich Islands},
		gt => q{Guatemala},
		gu => q{Guam},
		gw => q{Guinea-Bissau},
		gy => q{Guyana},
		hk => q{Hong Kong},
		hm => q{Heard and McDonald Islands},
		hn => q{Honduras},
		hr => q{Croatia},
		ht => q{Haiti},
		hu => q{Hungary},
		id => q{Indonesia},
		ie => q{Ireland},
		il => q{Israel},
		im => q{Isle of Man},
		in => q{India},
		io => q{British Indian Ocean Territory},
		iq => q{Iraq},
		ir => q{Iran},
		is => q{Iceland},
		it => q{Italy},
		je => q{Jersey},
		jm => q{Jamaica},
		jo => q{Jordan},
		jp => q{Japan},
		ke => q{Kenya},
		kg => q{Kyrgyzstan},
		kh => q{Cambodia},
		ki => q{Kiribati},
		km => q{Comoros},
		kn => q{St. Kitts and Nevis},
		kp => q{North Korea},
		kr => q{South Korea},
		kw => q{Kuwait},
		ky => q{Cayman Islands},
		kz => q{Kazakhstan},
		la => q{Laos},
		lb => q{Lebanon},
		lc => q{St. Lucia},
		li => q{Liechtenstein},
		lk => q{Sri Lanka},
		lr => q{Liberia},
		ls => q{Lesotho},
		lt => q{Lithuania},
		lu => q{Luxembourg},
		lv => q{Latvia},
		ly => q{Libya},
		ma => q{Morocco},
		mc => q{Monaco},
		md => q{Moldova},
		me => q(Montenegro),
		mf => q{St. Martin},
		mg => q{Madagascar},
		mh => q{Marshall Islands},
		mk => q{Macedonia},
		ml => q{Mali},
		mm => q{Myanmar},
		mn => q{Mongolia},
		mo => q{Macau},
		mp => q{Northern Mariana Islands},
		mq => q{Martinique},
		mr => q{Mauritania},
		ms => q{Montserrat},
		mt => q{Malta},
		mu => q{Mauritius},
		mv => q{Maldives},
		mw => q{Malawi},
		mx => q{Mexico},
		my => q{Malaysia},
		mz => q{Mozambique},
		na => q{Namibia},
		nc => q{New Caledonia},
		ne => q{Niger},
		nf => q{Norfolk Island},
		ng => q{Nigeria},
		ni => q{Nicaragua},
		nl => q{Netherlands},
		no => q{Norway},
		np => q{Nepal},
		nr => q{Nauru},
		nu => q{Niue},
		nz => q{New Zealand},
		om => q{Oman},
		pa => q{Panama},
		pe => q{Peru},
		pf => q{French Polynesia},
		pg => q{Papua New Guinea},
		ph => q{Philippines},
		pk => q{Pakistan},
		pl => q{Poland},
		pm => q{St. Pierre and Miquelon},
		pn => q{Pitcairn Island},
		pr => q{Puerto Rico},
		ps => q{Palestine},
		pt => q{Portugal},
		pw => q{Palau},
		py => q{Paraguay},
		qa => q{Qatar},
		re => q{Reunion Island},
		ro => q{Romania},
		rs => q(Serbia),
		ru => q{Russian Federation},
		rw => q{Rwanda},
		sa => q{Saudi Arabia},
		sb => q{Solomon Islands},
		sc => q{Seychelles},
		sd => q{Sudan},
		se => q{Sweden},
		sg => q{Singapore},
		sh => q{St. Helena},
		si => q{Slovenia},
		sj => q{Svalbard and Jan Mayen Islands},
		sk => q{Slovak Republic},
		sl => q{Sierra Leone},
		sm => q{San Marino},
		sn => q{Senegal},
		so => q{Somalia},
		sr => q{Suriname},
		st => q{Sao Tome and Principe},
		su => q{Soviet Union},
		sv => q{El Salvador},
		sy => q{Syria},
		sz => q{Swaziland},
		tc => q{Turks and Caicos Islands},
		td => q{Chad},
		tf => q{French Southern Territories},
		tg => q{Togo},
		th => q{Thailand},
		tj => q{Tajikistan},
		tk => q{Tokelau},
		tl => q{Timor-Leste},
		tm => q{Turkmenistan},
		tn => q{Tunisia},
		to => q{Tonga},
		tp => q{East Timor},
		'tr' => q{Turkey},
		tt => q{Trinidad and Tobago},
		tv => q{Tuvalu},
		tw => q{Taiwan},
		tz => q{Tanzania},
		ua => q{Ukraine},
		ug => q{Uganda},
		uk => q{UK},
		um => q{US Minor Outlying Islands},
		us => q{US},
		uy => q{Uruguay},
		uz => q{Uzbekistan},
		va => q{Holy See},
		vc => q{St. Vincent and the Grenadines},
		ve => q{Venezuela},
		vg => q{British Virgin Islands},
		vi => q{US Virgin Islands},
		vn => q{Vietnam},
		vu => q{Vanuatu},
		wf => q{Wallis and Futuna Islands},
		ws => q{Western Samoa},
		ye => q{Yemen},
		yt => q{Mayotte},
		yu => q{Yugoslavia},
		za => q{South Africa},
		zm => q{Zambia},
		zw => q{Zimbabwe}
);


1;