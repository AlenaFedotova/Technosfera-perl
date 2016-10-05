package Local::MusicLibrary::Printing;

use strict;
use warnings;


=encoding utf8

=head1 NAME

Local::MusicLibrary - core music library module

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

=cut

my @col0 = ("band", "year", "album", "track", "format");

sub Print {
	my $ref = shift;
	my @col;
	ColProcess(\@col, shift);

	if ($col[0] ne -1 && $#$ref != -1) {

		my %max;
		my $sum = Maximums ($ref, \@col, \%max);

		print '/', '-'x($sum), "\\\n";
		for (my $i = 0; $i < $#$ref+1; $i++) {
			PrintString($ref->[$i], \@col, \%max);
			if ($i != $#$ref) {
				PrintLine($ref->[$i], \@col, \%max);
			}
		}
		print "\\", "-"x($sum), "/\n";
	}

}

sub ColProcess {
	my $col = shift;
	my $c = shift;

	$#$col = -1;

	if ($c eq -1) {@$col = @col0}
	elsif (!$c) {push @$col, -1}
	else {
		@$col = split ',', $c;
		for (@$col) {if (!($_ ~~ @col0)) {die "Bad columns"}}
	}

}

sub Maximums {
	my $ref = shift;
	my $col = shift;
	my $max = shift;
	my $sum = -1;
	for (@col0) {$max->{$_} = 0}
	for (@$ref) {
		my $x = $_;
		for (@col0) {
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
	for (my $k=0; $k < $#$col+1; $k++) {
		if ($k == 0) {print "|", "-"x($max->{$col->[$k]} + 2)}
		else {print "+", "-"x($max->{$col->[$k]} + 2)}
		}
	print "|\n";
}

1;
