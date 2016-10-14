package Local::Reducer::MaxDiff;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Reducer::MaxDiff

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Reducer);

sub reduce_n {
	my ($self, $n) = @_;
	while ($n > 0 && $self->{now} ne 'undef') {
		my $tmpobj = $self->{row_class}->new(str => $self->{now});
		my $mbmax = $tmpobj->get($self->{top}, 0) - $tmpobj->get($self->{bottom}, 0);
		if ($mbmax > $self->{reduced}) {$self->{reduced} = $mbmax}
		$self->{now} = $self->{source}->next();
		$n--;
	}
	return $self->{reduced};
}

sub reduce_all {
	my ($self) = @_;
	while ($self->{now} ne 'undef') {
		my $tmpobj = $self->{row_class}->new(str => $self->{now});
		my $mbmax = $tmpobj->get($self->{top}, 0) - $tmpobj->get($self->{bottom}, 0);
		if ($mbmax > $self->{reduced}) {$self->{reduced} = $mbmax}
		$self->{now} = $self->{source}->next();
	}
	return $self->{reduced};
}

sub reduced {
	my ($self) = @_;
	return $self->{reduced};
}


1;
