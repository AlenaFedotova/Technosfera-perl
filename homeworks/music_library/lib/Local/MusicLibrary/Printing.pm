package Local::MusicLibrary::Printing;

use strict;
use warnings;
use List::MoreUtils;


=encoding utf8

=head1 NAME

Local::MusicLibrary - core music library module

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut


sub Print {
	my $ref = shift;
	my $col = shift;

	if ($col->[0] ne -1 && $#$ref != -1) {

		my %max;
		my $sum = Maximums ($ref, $col, \%max);

		print '/', '-'x($sum), "\\\n";
		for my $i (0..$#$ref) {
			PrintString($ref->[$i], $col, \%max);
			if ($i != $#$ref) {
				PrintLine($ref->[$i], $col, \%max);
			}
		}
		print "\\", "-"x($sum), "/\n";
	}

}

sub Maximums {
	my $ref = shift;
	my $col = shift;
	my $max = shift;
	my $sum = -1;
	for (@$col) {$max->{$_} = 0}
	for (@$ref) {
		my $x = $_;
		for (@$col) {
			my $l = length $x->{$_};
			if ($l > $max->{$_}) {$max->{$_} = $l}
		}	
	}
	for (@$col) {$sum += $max->{$_} + 3}
	return $sum;
}

sub PrintString {
	my $x = shift;
	my $col = shift;
	my $max = shift;
	for (@$col) {
		print "|", " "x($max->{$_} + 1 - length($x->{$_})), $x->{$_}, " ";
	}
	print "|\n";
}

sub PrintLine {
	my $x = shift;
	my $col = shift;
	my $max = shift;
	for my $i (0..$#$col) {
		if ($i == 0) {print "|", "-"x($max->{$col->[$i]} + 2)}
		else {print "+", "-"x($max->{$col->[$i]} + 2)}
		}
	print "|\n";
}

1;
