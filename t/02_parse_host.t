#!perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use URI::ParseSearchString::Heuristic;
use URI::ParseSearchString::Heuristic::URI;

my $parser = URI::ParseSearchString::Heuristic->new();

for my $test (
	['google.com', {
          engine_simple_name => 'Google',
          engine_full_name   => 'Google',
          engine_key         => 'com.google',
    }],
	['google.pt', {
          engine_country     => 'Portugal',
          engine_simple_name => 'Google',
          engine_full_name   => 'Google Portugal',
          engine_key         => 'pt.google'
    }],
	['atalhocerto.com.br', {
          engine_country     => 'Brazil',
          engine_simple_name => 'Atalhocerto',
          engine_full_name   => 'Atalhocerto',
          engine_key         => 'br.com.atalhocerto',
        }],
	['buscador.lycos.es', {
          engine_country     => 'Spain',
          engine_simple_name => 'Lycos',
          engine_full_name   => 'Lycos Spain',
          engine_key         => 'es.lycos'
        }],
     ['xl.pt', {
     	engine_country       => 'Portugal',
     	engine_simple_name   => 'XL',
     	engine_full_name     => 'XL',
     	engine_key           => 'pt.xl'
     }],
     ['www.xl.pt', {
     	engine_country     => 'Portugal',
     	engine_simple_name => 'XL',
     	engine_full_name   => 'XL',
     	engine_key         => 'pt.xl'
     }],
     ['uk.altavista.com', {
     	engine_country     => 'United Kingdom',
     	engine_simple_name => 'Altavista',
     	engine_full_name   => 'Altavista United Kingdom',
     	engine_key         => 'com.altavista.uk'
     }],
	['uk.search.yahoo.com', {
		engine_country     => 'United Kingdom',
		engine_simple_name => 'Yahoo!',
     	engine_full_name   => 'Yahoo! United Kingdom',
     	engine_key         => 'com.yahoo.search.uk',
	}],
	['in.search.yahoo.com', {
		engine_country => 'India',
		engine_simple_name => 'Yahoo!',
		engine_full_name   => 'Yahoo! India',
		engine_key         => 'com.yahoo.search.in',
	}],
	['record.pt', {
		engine_country     => 'Portugal',
		engine_simple_name => 'Jornal Record',
		engine_full_name   => 'Jornal Record',
		engine_key         => 'pt.record',
	}],
	['blogsearch.google.co.uk', {
		engine_simple_name => 'Google Blog Search',
		engine_full_name   => 'Google Blog Search',
		engine_key         => 'com.google.blogsearch',
	}],
	['bligsearch.google.com', {
		engine_simple_name => 'Google',
		engine_full_name   => 'Google',
		engine_key         => 'com.google',
	}],
) {
	my ($host, $details) = @$test;
	my $data = { meta_url_full => "http://$host/?q=foo" };

	URI::ParseSearchString::Heuristic::URI->parse( $data );

	my $result = $parser->_parse_host( $data );
	note Dumper $data;
}

done_testing;
