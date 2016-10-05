package Local::MusicLibrary::Processing;

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

sub Process {
	my $ref = shift;
	my $opt = shift;
	GrepArray($ref, $opt);
	SortArray($ref, $opt->{sort});
}

sub GrepArray {
	my $ref = shift;
	my $opt = shift;

	for(@col0) {
		my $x=$_;
		if ($opt->{$x}) {
			if ($x eq 'year') {@$ref = grep {$_->{$x} == $opt->{$x}} @$ref}
			else {@$ref = grep {$_->{$x} eq $opt->{$x}} @$ref}
		}
	}
}

sub SortArray {
	my $ref = shift;
	my $sort = shift;

	if ($sort eq 'year') {@$ref = sort {$a->{$sort}+0 <=> $b->{$sort}+0} @$ref}
	elsif ($sort ~~ @col0) {@$ref = sort {$a->{$sort} cmp $b->{$sort}} @$ref}
	elsif (!$sort) {}
	else {die "Bad sorting"}
}

1;
