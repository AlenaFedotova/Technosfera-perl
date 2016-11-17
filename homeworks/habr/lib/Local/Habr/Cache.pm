package Local::Habr::Cache;

use strict;
use warnings;
use Cache::Memcached::Fast;
use Mouse;
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

has memd => (is => 'rw', isa => 'Cache::Memcached::Fast');
has server => (is => 'ro', isa => 'Str', default => '127.0.0.1:11212');


sub init {
	my $self = shift;

	$self->{memd} = Cache::Memcached::Fast->new({servers => [{address => $self->{server}}]});
}

sub take_user {
	my $self = shift;
	my $user = shift;

	return $self->{memd}->get($user)
}

sub add_user {
	my $self = shift;
	my $user = shift;

	$self->{memd}->set($user->{username}, $user)
}

1;
