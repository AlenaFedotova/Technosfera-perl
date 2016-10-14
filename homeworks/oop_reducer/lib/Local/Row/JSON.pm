package Local::Row::JSON;

use strict;
use warnings;

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

sub get {
	my ($self, $name, $default) = @_;
	my $i = index $self->{str}, '"'.$name.'"';
	if ($i != -1) {
		my $str;
		my $tmp;
		($tmp, $str) = split '"'.$name.'"', $self->{str}, 2;
		$str =~ s/\}\s*$//;
		$str =~ s/^\s*:([^,]*).*$/$1/s;
		return $str;
	}
	else {
		return $default;
	}
}

1;
