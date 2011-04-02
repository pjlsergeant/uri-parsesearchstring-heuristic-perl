#!perl

use strict;
use warnings;

use YAML::XS;
use URI::Sequin;
use URI::ParseSearchString;
use URI::ParseSearchString::Heuristic;
use URI::ParseSearchString::More;

my @cases;
my $uparse = new URI::ParseSearchString;
my $more = new URI::ParseSearchString::More;

*URI::ParseSearchString::More::get_mech = sub { fakemech->new() };

while (my $line = <STDIN>) {
	chomp $line;
	next unless $line;
	$line .= "http://$line" if index($line, 'http');

	my $output = {
		url   => $line,
		terms => '',
		name  => '',
		full_name => '',
	};

	$output->{'guess'}->{'sequin'} = {
		terms => (URI::Sequin::key_extract( $line ) || ''),
		name  => (URI::Sequin::se_extract(  $line ) || '')
	};

	$output->{'guess'}->{'pss'} = {
		terms => ( $uparse->se_term( $line ) || '' ),
		name  => ( $uparse->se_name( $line ) || '' )
	};

	$output->{'guess'}->{'pss_m'} = {
		terms => (
			$more->se_term( $line ) ||
			$more->guess( $line )   ||
			'' ),
		name  => ( $more->se_name( $line ) || '' )
	};

	my $hresult = URI::ParseSearchString::Heuristic->parse( $line );
	if ( $hresult ) {
		$output->{'terms'} = $hresult->{'search_terms'} || '';
		$output->{'name'} = $hresult->{'engine_simple_name'} || '';
		$output->{'full_name'} = $hresult->{'engine_full_name'} || '';
		if ( $hresult->{'search_terms_location'} ) {
			$output->{'location'} = $hresult->{'search_terms_location'};
		}
	}

	push( @cases, $output );

}

print Dump \@cases;

package fakemech;
sub new    { bless {}, 'fakemech' }
sub get    {''}
sub status {''}
sub title  {''}
