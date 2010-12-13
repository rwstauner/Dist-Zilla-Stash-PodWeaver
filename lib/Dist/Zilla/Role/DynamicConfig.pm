package Dist::Zilla::Role::DynamicConfig;
# ABSTRACT: A Role that accepts a dynamic configuration

use strict;
use warnings;
use Moose::Role;

=attr _config

A hashref where the dynamic options will be stored.

Do not attempt to assign to this from your F<dist.ini>.

=cut

has _config => (
    is       => 'ro',
    isa      => 'HashRef',
    default  => sub { +{} }
);

=method BUILDARGS

Copied/modified from L<Dist::Zilla::Plugin::Prereqs>
to allow arbitrary values to be specified.

This overwrites the L<Class::MOP::Instance> method
called to prepare arguments before instantiation.

It separates the expected arguments
and places the remaining unknown arguments into I<_config>.

=cut

sub BUILDARGS {
	my ($class, @arg) = @_;
	my %copy = ref $arg[0] ? %{$arg[0]} : @arg;

	my $zilla = delete $copy{zilla};
	my $name  = delete $copy{plugin_name};

	confess 'do not try to pass _config as a build arg!'
		if $copy{_config};

	return {
		zilla => $zilla,
		plugin_name => $name,
		_config     => \%copy,
	}
}

no Moose::Role;
1;

=for :stopwords BUILDARGS

=head1 DESCRIPTION

This is a role for a L<Plugin|Dist::Zilla::Role::Plugin>
(or possibly other classes)
that accepts a dynamic configuration.

=cut
