package Local::Habr::Cache;

use strict;
use warnings;
use Cache::Memcached::Fast;
use Moose;
use feature 'say';
use DDP;

=encoding utf8

=head1 NAME

Local::Habr - habrahabr.ru crawler

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

has memd => (is => 'rw', isa => 'Cache::Memcached::Fast', builder => '_build_memd', lazy => 1);
has server => (is => 'ro', isa => 'Str', default => '127.0.0.1:11212');

sub _build_memd {
	my ($self) = @_;
	return Cache::Memcached::Fast->new({servers => [{address => $self->{server}}]});
}

sub take_user {
	my ($self, $user) = @_;

	return $self->memd->get($user)
}

sub add_user {
	my ($self, $user) = @_;

	$self->memd->set($user->{username}, $user)
}

1;
