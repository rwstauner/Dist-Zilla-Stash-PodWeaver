package Dist::Zilla::Stash::PodWeaver;
# ABSTRACT: A stash of config options for Pod::Weaver

=head1 SYNOPSIS

	# dist.ini

	[@YourFavoritePluginBundle]

	[%PodWeaver]
	-StopWords:include = WordsIUse ThatAreNotWords

=cut

use strict;
use warnings;
use Pod::Weaver::Config::Assembler ();
use Moose;
with 'Dist::Zilla::Role::Stash::Plugins';

=method expand_package

Expand shortened package monikers to the full package name.

Changes leading I<+> to I<=> and then passes the value to
I<expand_package> in L<Pod::Weaver::Config::Assembler>.

See L</USAGE> for a description.

=cut

sub expand_package {
	my ($class, $pack) = @_;
	# Cannot start an ini line with '='
	$pack =~ s/^\+/=/;
	Pod::Weaver::Config::Assembler->expand_package($pack);
}

1;

=for stopwords PluginBundles PluginName dists zilla dist-zilla Flibberoloo ini

=head1 DESCRIPTION

This performs the L<Dist::Zilla::Role::Stash> role
(using L<Dist::Zilla::Role::DynamicConfig>
and    L<Dist::Zilla::Role::Stash::Plugins>).

When using L<Dist::Zilla::Plugin::PodWeaver>
with a I<config_plugin> it's difficult to pass more
configuration options to L<Pod::Weaver> plugins.

This is often the case when using a
L<Dist::Zilla::PluginBundle|Dist::Zilla::Role::PluginBundle>
that uses a
L<Pod::Weaver::PluginBundle|Pod::Weaver::PluginBundle::Default>.

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
have a look at
L<Dist::Zilla::Role::Stash::Plugins/get_stashed_config> and
L<Dist::Zilla::Role::Stash::Plugins/merge_stashed_config>
to see easy ways to get values from this stash.

Please contact me (and/or send patches) if something doesn't work
like you think it should.

=back

=cut
