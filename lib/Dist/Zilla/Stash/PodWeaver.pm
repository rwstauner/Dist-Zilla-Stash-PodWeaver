package Dist::Zilla::Stash::PodWeaver;
# ABSTRACT: A stash of config options for Pod::Weaver

=head1 SYNOPSIS

	# dist.ini

	[@YourFavoritePluginBundle]

	[%PodWeaver]
	-StopWords:include = WordsIUse ThatAreNotWords

=cut

use Pod::Weaver::Config::Assembler ();
use Moose;
with 'Dist::Zilla::Role::Stash';

=attr _config

A hashref where the dynamic options will be stored.

Do not attempt to assign to this from your F<dist.ini>.

Rather than accessing this directly,
consider L</get_stashed_config> or L</merge_stashed_config>.

=cut

has _config => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} }
);

=attr argument_separator

A regular expression that will capture
the package name in C<$1> and
the attribute name in C<$2>.

Defaults to C<< ^(.+?)\W+(\w+)$ >>
which means the package variable and the attribute
will be separated by non-word characters
(which assumes the attributes will be
only word characters/valid perl identifiers).

You will need to set this attribute in your stash
if you need to assign to an attribute in a package that contains
non-word characters.
This is an example (taken from the tests in F<t/ini-sep>).

	# dist.ini
	[%PodWeaver]
	argument_separator = ^([^|]+)\|([^|]+)$
	-PlugName|Attr::Name = oops
	+Mod::Name|!goo-ber = nuts

=cut

has argument_separator => (
    is       => 'ro',
    isa      => 'Str',
	# "Module::Name:variable" "-Plugin/variable"
    default  => '^(.+?)\W+(\w+)$'
);

# Copied/modified from Dist::Zilla::Plugin::Prereqs
# to allow arbitrary values to be specified.
# This overwrites the Class::MOP::Instance method
# called to prepare arguments before instantiation.
sub BUILDARGS {
	my ($class, @arg) = @_;
	my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

	my $zilla = delete $copy{zilla};
	my $name  = delete $copy{plugin_name};

	# keys for other plugins should include non-word characters
	# (like "-Plugin::Name:variable"), so any keys that are only
	# word characters (valid identifiers) are for this object.
	my @local = grep { /^\w+$/ } keys %copy;
	my %other;
	@other{@local} = delete @copy{@local}
		if @local;

	confess "don't try to pass _config as a build arg!"
		if $other{_config};

	return {
		zilla => $zilla,
		plugin_name => $name,
		_config     => \%copy,
		%other,
	}
}

=method expand_package

Expand shortened package monikers to the full package name.

Changes leading I<+> to I<=> and then passes value to
L<Pod::Weaver::Config::Assembler/expand_package>.

See L</USAGE> for a description.

=cut

sub expand_package {
	my ($class, $pack) = @_;
	# Cannot start an ini line with '='
	$pack =~ s/^\+/=/;
	Pod::Weaver::Config::Assembler->expand_package($pack);
}

=method get_stashed_config

Return a hashref of the config arguments for the plugin
determined by C<< ref($plugin) >>.

This is a slice of the I<_config> attribute of the Stash
appropriate for the plugin passed to the method.

	# with a stash of:
	# _config => {
	#   '-APlug:attr1'   => 'value1',
	#   '-APlug:second'  => '2nd',
	#   '-OtherPlug:attr => '0'
	# }

	# from inside Pod::Weaver::Plugin::APlug

	my $stashed =
	Dist::Zilla::Stash::PodWeaver->get_stashed_config($self, \%opts);

	# $stashed => {
	#   'attr1'   => 'value1',
	#   'second'  => '2nd'
	# }

Possible options to be included in the hashref:

=for :list
* I<zilla>
The current dist-zilla object (which contains the stash).

=cut

sub get_stashed_config {
	my ($class, $plugin, $opts) = @_;
	$opts ||= {};
	return unless my $zilla = $opts->{zilla};
	return unless my $stash = $zilla->stash_named('%PodWeaver');

	# use ref() rather than $plugin->plugin_name() because we want to match
	# the full package name as returned by expand_package() below
	# rather than '@Bundle/ShortPluginName'
	my $name = ref($plugin);

	my $config = $stash->_config;
	my $stashed = {};
	my $splitter = qr/${\ $stash->argument_separator }/;

	while( my ($key, $value) = each %$config ){
		my ($plug, $attr) = ($key =~ $splitter);
		my $pack = $class->expand_package($plug);

		$stashed->{$attr} = $value
			if $pack eq $name;
	}
	return $stashed;
}

=method merge_stashed_config

	Dist::Zilla::Stash::PodWeaver->get_stashed_config($plugin, \%opts);

Get the stashed config (see L</get_stashed_config>),
then attempt to merge it into the plugin.

This require the plugin's attributes to be writable (C<'rw'>).

It will attempt to push onto array references and
concatenate onto existing strings (joined by a space).
It will overwrite any other types.

Possible options:

=for :list
* I<stashed>
A hashref like that returned from L</get_stashed_config>.
If not present, L</get_stashed_config> will be called.
* I<zilla>
The current dist-zilla object.
This is only needed if I<stashed> is not present.

=cut

sub merge_stashed_config {
	my ($class) = shift;
	my ($plugin, $opts) = @_;
	$opts ||= {};
	my $stashed = $opts->{stashed};
	return unless $stashed ||= $class->get_stashed_config($plugin, $opts);

	while( my ($key, $value) = each %$stashed ){
		# call attribute writer (attribute must be 'rw'!)
		my $attr = $plugin->meta->find_attribute_by_name($key);
		my $type = $attr->type_constraint;
		my $previous = $plugin->$key;
		if( $previous ){
			if( UNIVERSAL::isa($previous, 'ARRAY') ){
				push(@$previous, $value);
			}
			elsif( $type->name eq 'Str' ){
				# TODO: pass in string for joining
				$plugin->$key(join(' ', $previous, $value));
			}
			#elsif( $type->name eq 'Bool' )
			else {
				$plugin->$key($value);
			}
		}
		else {
			$value = [$value]
				if $type->name =~ /^arrayref/i;

			$plugin->$key($value);
		}
	}
}

1;

=for stopwords PluginBundles PluginName dists zilla dist-zilla Flibberoloo ini

=head1 DESCRIPTION

This performs the L<Dist::Zilla::Role::Stash> role.

When using L<Dist::Zilla::Plugin::PodWeaver>
with a I<config_plugin> it's difficult to pass more
configuration options to L<Pod::Weaver> plugins.

This is often the case when using a
L<Dist::Zilla::PluginBundle|Dist::Zilla::Role::PluginBundle>
that uses a
L<Pod::Weaver::PluginBundle|Pod::Weaver::Role::PluginBundle>.

This stash is intended to allow you to set other options in your F<dist.ini>
that can be accessed by L<Pod::Weaver> plugins.

Because you know how you like your dists built,
(and you're using PluginBundles to do it)
but you need a little extra customization.

=head1 USAGE

The attributes should be named like
C<PluginName:attributes>.
The PluginName will be passed to
C<< Pod::Weaver::Config::Assembler->expand_package() >>
so the PluginName should include the leading character
to identify its type:

=for :list
* C<> (no character) (Pod::Weaver::Section::I<Name>)
* C<-> Plugin (Pod::Weaver::Plugin::I<Name>)
* C<@> Bundle (Pod::Weaver::PluginBundle::I<Name>)
* C<+> Full Package Name (I<Name>)
An ini config line cannot start with an I< = >
so this module will convert any lines that start with I< + > to I< = >.

For example

	Complaints:use_fake_email = 1

Would set the 'use_fake_email' attribute to '1'
for the [fictional] I<Pod::Weaver::Section::Complaints> plugin.

	-StopWords:include = Flibberoloo

Would add 'Flibberoloo' to the list of stopwords
added by the L<Pod::Weaver::Plugin::StopWords> plugin.

	+Some::Other::Module:silly = 1

Would set the 'silly' flag to true on I<Some::Other::Module>.

=head1 BUGS AND LIMITATIONS

=over

=item *

Arguments can only be specified in a F<dist.ini> stash once,
even if the plugin would normally allow multiple entries
in a F<weaver.ini>.  Since the arguments are dynamic (unknown to the class)
the class cannot specify which arguments should accept multiple values.

=item *

Including the package name gives the options a namespace
(instead of trying to set the I<include> attribute for 2 different plugins).

Unfortunately this does not automatically set the options on the plugins.
The plugins need to know to use this stash.

So if you'd like to be able to use this stash with a L<Pod::Weaver>
plugin that doesn't support it, please contact that plugin's author(s)
and let them know about this module.

If you are a L<Pod::Weaver> plugin author,
have a look at the L</get_stashed_config> and L</merge_stashed_config> methods
to see easy ways to get values from this stash.

Please contact me (and/or send patches) if something doesn't work
like you think it should.

=back

=cut
