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

has _config => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} }
);

has argument_separator => (
    is       => 'ro',
    isa      => 'Str',
	# plugin name and variable separated by non-word chars
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

sub expand_package {
	my ($class, $pack) = @_;
	# Cannot start an ini line with '='
	$pack =~ s/^\+/=/;
	Pod::Weaver::Config::Assembler->expand_package($pack);
}

sub get_stashed_config {
	my ($class, $plugin, $document, $input) = @_;
	return unless my $zilla = $input->{zilla};
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

sub load_stashed_config {
	my ($class) = shift;
	my ($plugin, $document, $input, $stashed) = @_;
	return unless $stashed ||= $class->get_stashed_config(@_);

	while( my ($key, $value) = each %$stashed ){
		# call attribute writer (attribute must be 'rw'!)
		# TODO: concatenate rather than overwrite
		# TODO: determine attr 'type'... if ArrayRef or Str
		$plugin->$key($value);
	}
}

1;

=for stopwords PluginBundles dists

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
* C< > (no character) (Pod::Weaver::Section::I<Name>)
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

=head1 BUGS AND LIMITATIONS

Including the package name gives the options a namespace
(instead of trying to set the I<include> attribute for 2 different plugins).

Unfortunately this does not automatically set the options on the plugins.
The plugins need to know to use this stash.

So if you'd like to be able to use this stash with a L<Pod::Weaver>
plugin that doesn't support it, please contact that plugin's author(s)
and let them know about this module.

If you are a L<Pod::Weaver> plugin author,
have a look at the L</get_stashed_config> and L</load_stashed_config> methods
to see easy ways to get values from this stash.

Please contact me (and/or send patches) if something doesn't work
like you think it should.

=cut
