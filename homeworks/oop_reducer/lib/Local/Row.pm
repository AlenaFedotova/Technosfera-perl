package Local::Row;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Row

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Object);

sub init {
	my ($self) = @_;
	$self->parse();
}

sub get {
	my ($self, $name, $default) = @_;
	if (defined($self->{source}->{$name})) {return $self->{source}->{$name}} 
	else {return $default}
}

1;
