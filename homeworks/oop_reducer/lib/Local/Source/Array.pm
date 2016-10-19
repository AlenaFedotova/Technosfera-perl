package Local::Source::Array;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Array

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Source);

sub init {
	my ($self) = @_;
	$self->{i}=0;
}

sub next {
	my ($self) = @_;
	if ($self->{i} <= $#{$self->{array}}) {return $self->{array}->[$self->{i}++]}
	else {return undef}
}

1;
