use strict;
use warnings;
use Test::More;

use Dist::Zilla::Tester;

my %confs = (
	't/ini-none' => undef,
	't/ini-sep'  => {
		'argument_separator'  => '^([^|]+)\|([^|]+)$',
		_config => {
			'-PlugName|attr-name' => 'oops',
			'+Mod::Name|!goober'  => 'nuts',
		}
	},
	't/ini-test' => {
		'argument_separator'  => '^(.+?)\W+(\w+)$',
		_config => {
			'@Bundle-fakeattr'    => 'fakevalue1',
			'-Plugin/fakeattr'    => 'fakevalue2',
			'Section->heading'    => 'head5',
			'-Plug::Name::config' => 'confy',
		}
	}
);

plan tests => (scalar keys %confs);

foreach my $dir ( glob("t/ini-*") ){
	next unless -d $dir;

	my $zilla = Dist::Zilla::Tester->from_config(
		{ dist_root => $dir },
		{}
	);

	$zilla->build;

	is_deeply($zilla->stash_named('%PodWeaver'), $confs{$dir}, "stash matches in $dir");
}
