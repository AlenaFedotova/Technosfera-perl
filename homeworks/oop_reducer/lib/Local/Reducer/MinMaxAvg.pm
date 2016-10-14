package Local::Reducer::MinMaxAvg;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MinMaxAvg

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Reducer);
use Local::Reducer::MinMaxAvg::Reduced;

sub init {
	my ($self) = @_;
	$self->{reduced} = $self->{initial_value};
	$self->{now} = $self->{source}->next();
	$self->{sum} = 0;
	$self->{n} = 0;
	$self->{min} = 'undef';
	$self->{max} = 'undef';
}

sub reduce_n {
	my ($self, $n) = @_;
	while ($n > 0 && $self->{now} ne 'undef') {
		$self->{n}++;
		my $tmp = $self->{row_class}->new(str => $self->{now})->get($self->{field}, 0)+0;
		$self->{sum} += $tmp;
		if ($self->{min} eq 'undef' || $self->{min} > $tmp) {$self->{min} = $tmp} 
		if ($self->{max} eq 'undef' || $self->{max} < $tmp) {$self->{max} = $tmp} 
		$self->{now} = $self->{source}->next();
		$n--;
	}
	return $self->reduced();
}

sub reduce_all {
	my ($self) = @_;
	while ($self->{now} ne 'undef') {
		$self->{n}++;
		my $tmp = $self->{row_class}->new(str => $self->{now})->get($self->{field}, 0)+0;
		$self->{sum} += $tmp;
		if ($self->{min} eq 'undef' || $self->{min} > $tmp) {$self->{min} = $tmp} 
		if ($self->{max} eq 'undef' || $self->{max} < $tmp) {$self->{max} = $tmp} 
		$self->{now} = $self->{source}->next();
	}
	return $self->reduced();
}

sub reduced {
	my ($self) = @_;
	if ($self->{n} == 0) {
		return Local::Reducer::MinMaxAvg::Reduced->new(avg => 'undef', min => 'undef', max => 'undef')
	}
	else {
		return Local::Reducer::MinMaxAvg::Reduced->new(avg => $self->{sum}/$self->{n}, min => $self->{min}, max => $self->{max})
	}
}

1;
