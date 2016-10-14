package Local::Reducer;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer - base abstract reducer

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Object);

sub init {
	my ($self) = @_;
	$self->{reduced} = $self->{initial_value};
	$self->{now} = $self->{source}->next();
}

sub reduce_n {
	my ($self, $n) = @_;
	return;
}

sub reduce_all {
	my ($self) = @_;
	return;
}

sub reduced {
	my ($self) = @_;
	return;
}

1;
