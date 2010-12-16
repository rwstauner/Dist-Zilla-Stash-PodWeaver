use strict;
use warnings;
use Test::More;
use Test::MockObject;

use Dist::Zilla::Tester;

my %confs = (
	't/ini-none' => undef,
	't/ini-sep'  => {
		mods => {
			'Pod::Weaver::Plugin::PlugName' => { 'Attr::Name' => 'oops' },
			'Mod::Name' => { '!goo-ber' => 'nuts', pea => 'nut' }
		},
		'argument_separator'  => '^([^|]+)\|([^|]+)$',
		_config => {
			'-PlugName|Attr::Name' => 'oops',
			'+Mod::Name|!goo-ber'  => 'nuts',
			'+Mod::Name|pea'       => 'nut',
		}
	},
	't/ini-test' => {
		mods => {
			'Pod::Weaver::PluginBundle::ABundle' => {'fakeattr' => 'fakevalue1'},
			'Pod::Weaver::Plugin::APlugin' => {'fakeattr' => 'fakevalue2'},
			'Pod::Weaver::Section::ASection' => {'heading' => 'head5'},
			'Pod::Weaver::Plugin::APlug::Name' => {'config' => 'confy'},
		},
		'argument_separator'  => '^(.+?)\W+(\w+)$',
		_config => {
			'@ABundle-fakeattr'    => 'fakevalue1',
			'-APlugin/fakeattr'    => 'fakevalue2',
			'ASection->heading'    => 'head5',
			'-APlug::Name::config' => 'confy',
		}
	}
);

my $mock = Test::MockObject->new;
foreach my $dir ( keys %confs ){

	my $zilla = Dist::Zilla::Tester->from_config(
		{ dist_root => $dir },
		{}
	);

	$zilla->build;

	my $mods = defined($confs{$dir}) ? delete($confs{$dir}->{mods}) : undef;

	is_deeply($zilla->stash_named('%PodWeaver'), $confs{$dir}, "stash matches in $dir");

	next unless $mods;

	foreach my $mod ( keys %$mods ){
		$mock->fake_module($mod, new => sub { bless {}, $_[0] });
		my $plug = $mod->new();
		isa_ok($plug, $mod);
		my $stash = $zilla->stash_named('%PodWeaver')->get_stashed_config($plug, {zilla => $zilla});
		is_deeply($stash, $mods->{$mod}, 'stashed config expected');
	}
}

done_testing;
