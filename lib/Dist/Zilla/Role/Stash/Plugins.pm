package Dist::Zilla::Role::Stash::Plugins;
# ABSTRACT: A Stash that stores arguments for plugins

use strict;
use warnings;
use Moose::Role;
with qw(
	Dist::Zilla::Role::DynamicConfig
	Dist::Zilla::Role::Stash
);

requires 'expand_package';

=attr _config

Contains the dynamic options.

Inherited from L<Dist::Zilla::Role::DynamicConfig>.

Rather than accessing this directly,
consider L</get_stashed_config> or L</merge_stashed_config>.

=cut

# _config inherited

=method BUILDARGS

This overwrites the L<Class::MOP::Instance> method
called to prepare arguments before instantiation.

It uses L<Dist::Zilla::Role::DynamicConfig/BUILDARGS>
to process the arguments initially,
then separates any local arguments from the keys in _config
(L</argument_separator>, for instance).

=cut

around 'BUILDARGS' => sub {
	my ($orig, $class, @arg) = @_;

	# Prepare arguments including zilla, plugin_name, and _config.
	my $built = $orig->($class, @arg);
	my $config  = $built->{_config};

	# keys for other plugins should include non-word characters
	# (like "-Plugin::Name:variable"), so any keys that are only
	# word characters (valid identifiers) are for this object.
	my @local = grep { /^\w+$/ } keys %$config;
	my %other;
	@other{@local} = delete @$config{@local}
		if @local;

	return {
		%$built,
		%other,
	}
};

=method stash_name

Returns the stash name (including the '%').

The default method attempts to guess it based on the package name.
For example: C<Dist::Zilla::Stash::Example> will return C<%Example>.

Overwrite this method if necessary.

=cut

sub stash_name {
	my $class = ref($_[0]) || $_[0];
	my ($pack) = ($class =~ /Dist::Zilla::Stash::(.+)$/);
	confess "Stash name could not be determined from package name"
		unless $pack;
	return "%$pack";
}

no Moose::Role;
1;

=for :stopwords BUILDARGS dist-zilla zilla

=head1 DESCRIPTION

This is a role for a L<Stash|Dist::Zilla::Role::Stash>
that stores arguments for other plugins.

Stashes performing this role must define I<expand_package>.

=cut
