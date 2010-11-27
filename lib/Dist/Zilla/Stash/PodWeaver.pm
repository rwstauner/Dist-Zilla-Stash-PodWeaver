package Dist::Zilla::Stash::PodWeaver;
# ABSTRACT: A stash of config options for Pod::Weaver

=head1 SYNOPSIS

	# dist.ini

	[%PodWeaver]
	stopwords = wordsiuse thatarenotwords

=cut

use Moose;
with 'Dist::Zilla::Role::Stash';

sub mvp_multivalue_args { qw(stopwords) }

has stopwords => (
	is  => 'rw',
	isa => 'ArrayRef[Str]',
	default => sub { [] }
);

1;

=for stopwords PluginBundles dists

=head1 DESCRIPTION

This performs this L<Dist::Zilla::Role::Stash> role.

When using L<Dist::Zilla::Plugin::PodWeaver>
with a I<config_plugin> it's difficult to pass more
configuration options to L<Pod::Weaver> plugins.

This stash is intended to allow you to set other options in your F<dist.ini>
that can be accessed by Pod::Weaver plugins.

Because you know how you like your dists built,
(and you're using PluginBundles to do it)
but you need a little extra customization.

=cut
