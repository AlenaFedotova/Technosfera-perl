package Local::Reducer::MinMaxAvg::Reduced;

use strict;
use warnings;

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

use parent qw(Local::Object);

sub get_min {
	my ($self) = @_;
	return $self->{min};
}

sub get_max {
	my ($self) = @_;
	return $self->{max};
}

sub get_avg {
	my ($self) = @_;
	return $self->{avg};
}

1;
