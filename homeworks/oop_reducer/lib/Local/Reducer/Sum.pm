package Local::Reducer::Sum;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::Sum

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Reducer);

sub reduce_one {
	my ($self) = @_;
	$self->{reduced} += $self->{row_class}->new(str => $self->{now})->get($self->{field}, 0);
	$self->{now} = $self->{source}->next();
}

1;
