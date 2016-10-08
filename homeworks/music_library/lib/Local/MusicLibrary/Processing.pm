package Local::MusicLibrary::Processing;

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

sub TakeArray {
	my $str = shift;
	my $ref = shift;
	my $col0 = shift;
	my $sep = shift;
	substr $str, 0, 2, "";
	for my $i (0..$#$sep) {($ref->{$col0->[$i]}, $str) = split ($sep->[$i], $str, 2)}
}

sub Process {
	my $ref = shift;
	my $opt = shift;
	my $col0 = shift;
	my $col = shift;
	my $is_num = shift;
	GrepArray($ref, $opt, $col0, $is_num);
	SortArray($ref, $opt->{sort}, $col0, $is_num);
	ColProcess($col, $opt->{columns}, $col0);
}

sub GrepArray {
	my $ref = shift;
	my $opt = shift;
	my $col0 = shift;
	my $is_num = shift;

	for(@$col0) {
		my $x=$_;
		if ($opt->{$x}) {
			if ($is_num->{$x}) {@$ref = grep {$_->{$x} == $opt->{$x}} @$ref}
			else {@$ref = grep {$_->{$x} eq $opt->{$x}} @$ref}
		}
	}
}
 
sub SortArray {
	my $ref = shift;
	my $sort = shift;
	my $col0 = shift;
	my $is_num = shift;

	if (List::MoreUtils::any {$_ eq $sort} @$col0) {
		if ($is_num->{$sort}) {@$ref = sort {$a->{$sort} <=> $b->{$sort}} @$ref}
		else {@$ref = sort {$a->{$sort} cmp $b->{$sort}} @$ref}
	}
	elsif (!$sort) {}
	else {die "Bad sorting"}
}

sub ColProcess {
	my $col = shift;
	my $c = shift;
	my $col0 = shift;

	if ($c eq -1) {@$col = @$col0}
	elsif (!$c) {push @$col, -1}
	else {
		@$col = split ',', $c;
		for my $x (@$col) {if (!(List::MoreUtils::any {$_ eq $x} @$col0)) {die "Bad columns"}}
	}

}

1;
