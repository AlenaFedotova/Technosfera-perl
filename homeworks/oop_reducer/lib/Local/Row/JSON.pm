package Local::Row::JSON;

use strict;
use warnings;
use JSON::XS;

=encoding utf8

=head1 NAME

Local::Row::JSON

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Row);

sub parse {
	my ($self) = @_;
	$self->{source} = JSON::XS->new->utf8->decode($self->{str})
}

1;
