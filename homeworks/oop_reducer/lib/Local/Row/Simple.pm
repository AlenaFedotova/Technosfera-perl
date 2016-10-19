package Local::Row::Simple;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Row::Simple

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Row);

sub parse {
	my ($self) = @_;
	my @tmp = split /,/, $self->{str};
	for (@tmp) {
		my ($name, $data) = split /:/, $_;
		$self->{source}->{$name} = $data;
	}
}

1;
