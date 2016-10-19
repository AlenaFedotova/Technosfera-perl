package Local::Source::Text;

use strict;
use warnings;

=encoding utf8

=head1 NAME

Local::Source::Text

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

use parent qw(Local::Source);

sub init {
	my ($self) = @_;
	if (!exists($self->{delimiter})) {$self->{delimiter} = "\n"}
	$self->{mod} = $self->{text};
}

sub next {
	my ($self) = @_;
	if ($self->{mod}) {
		my $tmp;
		($tmp, $self->{mod}) = split $self->{delimiter}, $self->{mod}, 2;
		return $tmp;
	}
	else {return undef}
}

1;
