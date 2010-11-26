package Dist::Zilla::Stash::PodWeaver;
# ABSTRACT: a stash of config options for Pod::Weaver

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
