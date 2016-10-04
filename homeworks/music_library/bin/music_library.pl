#!/usr/bin/env perl

use strict;
use warnings;
use Local::MusicLibrary;

my @col;
$#col = -1;
my %opt;
Local::MusicLibrary::GetOpting(\%opt, \@col);

my @arr;
$#arr = -1;
while (<>) {
	my $tmp;
	my %h;
	$tmp = \%h;
	Local::MusicLibrary::TakeArray $_, $tmp;
	push @arr, {%h};
}
Local::MusicLibrary::GrepArray \@arr, \%opt;
Local::MusicLibrary::SortArray \@arr, $opt{sort};
Local::MusicLibrary::Print \@arr, \@col;
